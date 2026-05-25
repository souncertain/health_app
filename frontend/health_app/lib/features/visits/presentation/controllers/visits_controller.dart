import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/local_notifications_service.dart';
import '../../domain/entities/medical_visit.dart';
import '../../domain/usecases/delete_medical_visit.dart';
import '../../domain/usecases/get_cached_medical_visits.dart';
import '../../domain/usecases/get_medical_visits.dart';
import '../../domain/usecases/save_medical_visit.dart';

class VisitsController extends ChangeNotifier {
  VisitsController({
    required GetCachedMedicalVisitsUseCase getCachedVisits,
    required GetMedicalVisitsUseCase getVisits,
    required SaveMedicalVisitUseCase saveVisit,
    required DeleteMedicalVisitUseCase deleteVisit,
    NotificationScheduler? notificationScheduler,
  }) : _getCachedVisits = getCachedVisits,
       _getVisits = getVisits,
       _saveVisit = saveVisit,
       _deleteVisit = deleteVisit,
       _notificationScheduler =
           notificationScheduler ?? LocalNotificationsService.instance;

  final GetCachedMedicalVisitsUseCase _getCachedVisits;
  final GetMedicalVisitsUseCase _getVisits;
  final SaveMedicalVisitUseCase _saveVisit;
  final DeleteMedicalVisitUseCase _deleteVisit;
  final NotificationScheduler _notificationScheduler;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<MedicalVisit> _visits = const [];
  bool _initialized = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<MedicalVisit> get visits => List.unmodifiable(_visits);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await _loadCached();
    unawaited(refresh(showLoading: _visits.isEmpty));
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      _setVisits(await _getVisits());
      await _notificationScheduler.syncVisitNotifications(_visits);
    } catch (_) {
      _errorMessage = 'РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РіСЂСѓР·РёС‚СЊ РІРёР·РёС‚С‹.';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
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
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕС…СЂР°РЅРёС‚СЊ РІРёР·РёС‚.',
      rethrowOnFailure: true,
    );
  }

  Future<void> rescheduleVisit(MedicalVisit visit, int timeInMinutes) async {
    await _persistVisit(
      visit.copyWith(timeInMinutes: timeInMinutes, updatedAt: DateTime.now()),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ РїРµСЂРµРЅРµСЃС‚Рё РІРёР·РёС‚.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteVisit(MedicalVisit visit) async {
    _isSaving = true;
    _errorMessage = null;
    final previousVisits = _visits;
    _setVisits(_visits.where((item) => item.id != visit.id).toList());
    notifyListeners();

    try {
      await _deleteVisit(visit.id);
      await _notificationScheduler.cancelVisitNotification(visit.id);
      await _reloadFromCache();
    } catch (_) {
      _setVisits(previousVisits);
      _errorMessage = 'РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ РІРёР·РёС‚.';
      notifyListeners();
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
    final previousVisits = _visits;
    _setVisits(_upsertVisit(_visits, visit));
    notifyListeners();

    try {
      await _saveVisit(visit);
      await _reloadFromCache();
    } catch (_) {
      _setVisits(previousVisits);
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

  Future<void> _loadCached() async {
    try {
      _setVisits(await _getCachedVisits());
      await _notificationScheduler.syncVisitNotifications(_visits);
    } catch (_) {
      // Keep empty state if cache loading fails.
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadFromCache() async {
    _setVisits(await _getCachedVisits());
    await _notificationScheduler.syncVisitNotifications(_visits);
  }

  void _setVisits(List<MedicalVisit> visits) {
    _visits = List<MedicalVisit>.from(visits)
      ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
  }

  List<MedicalVisit> _upsertVisit(
    List<MedicalVisit> source,
    MedicalVisit visit,
  ) {
    final updated = List<MedicalVisit>.from(source);
    final index = updated.indexWhere((item) => item.id == visit.id);
    if (index == -1) {
      updated.add(visit);
    } else {
      updated[index] = visit;
    }

    updated.sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return updated;
  }
}
