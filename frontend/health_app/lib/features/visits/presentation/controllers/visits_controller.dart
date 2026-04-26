import 'package:flutter/foundation.dart';

import '../../domain/entities/medical_visit.dart';
import '../../domain/usecases/delete_medical_visit.dart';
import '../../domain/usecases/get_medical_visits.dart';
import '../../domain/usecases/save_medical_visit.dart';

class VisitsController extends ChangeNotifier {
  VisitsController({
    required GetMedicalVisitsUseCase getVisits,
    required SaveMedicalVisitUseCase saveVisit,
    required DeleteMedicalVisitUseCase deleteVisit,
  }) : _getVisits = getVisits,
       _saveVisit = saveVisit,
       _deleteVisit = deleteVisit;

  final GetMedicalVisitsUseCase _getVisits;
  final SaveMedicalVisitUseCase _saveVisit;
  final DeleteMedicalVisitUseCase _deleteVisit;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<MedicalVisit> _visits = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<MedicalVisit> get visits => List.unmodifiable(_visits);

  Future<void> initialize() async {
    if (_isLoading || _visits.isNotEmpty) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final visits = await _getVisits();
      _visits = List<MedicalVisit>.from(visits)
        ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    } catch (_) {
      _errorMessage = 'Could not load visits.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MedicalVisit> visitsForType(MedicalVisitType type) {
    final filtered = _visits.where((visit) => visit.visitType == type).toList();
    filtered.sort(
      (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
    );
    return filtered;
  }

  MedicalVisit? nextVisitForType(MedicalVisitType type) {
    final now = DateTime.now();
    final filtered = visitsForType(type);

    for (final visit in filtered) {
      if (!visit.scheduledAt.isBefore(now)) {
        return visit;
      }
    }

    return filtered.isEmpty ? null : filtered.first;
  }

  Future<void> saveVisit({
    MedicalVisit? existingVisit,
    required String doctorName,
    required String specialty,
    required DateTime appointmentDate,
    required int timeInMinutes,
    required String location,
    required MedicalVisitType visitType,
  }) async {
    final now = DateTime.now();
    final visit =
        existingVisit?.copyWith(
          doctorName: doctorName,
          specialty: specialty,
          appointmentDate: MedicalVisit.normalizeDate(appointmentDate),
          timeInMinutes: timeInMinutes,
          location: location,
          visitType: visitType,
          updatedAt: now,
        ) ??
        MedicalVisit(
          id: 'visit-${now.microsecondsSinceEpoch}',
          doctorName: doctorName,
          specialty: specialty,
          appointmentDate: MedicalVisit.normalizeDate(appointmentDate),
          timeInMinutes: timeInMinutes,
          location: location,
          visitType: visitType,
          rating: visitType == MedicalVisitType.oneTime ? 4.9 : 4.8,
          createdAt: now,
          updatedAt: now,
        );

    await _persistVisit(
      visit,
      errorMessage: 'Could not save the visit.',
      rethrowOnFailure: true,
    );
  }

  Future<void> rescheduleVisit(MedicalVisit visit, int timeInMinutes) async {
    await _persistVisit(
      visit.copyWith(timeInMinutes: timeInMinutes, updatedAt: DateTime.now()),
      errorMessage: 'Could not reschedule the visit.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteVisit(MedicalVisit visit) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteVisit(visit.id);
      await refresh();
    } catch (_) {
      _errorMessage = 'Could not delete the visit.';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _persistVisit(
    MedicalVisit visit, {
    required String errorMessage,
    bool rethrowOnFailure = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _saveVisit(visit);
      await refresh();
    } catch (_) {
      _errorMessage = errorMessage;
      if (rethrowOnFailure) {
        rethrow;
      }
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
