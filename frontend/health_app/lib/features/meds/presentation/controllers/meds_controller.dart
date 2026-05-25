import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/local_notifications_service.dart';
import '../../domain/entities/medication.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/get_cached_medications.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/save_medication.dart';
import '../../domain/usecases/set_medication_daily_status.dart';

class MedicationReminderPreview {
  const MedicationReminderPreview({
    required this.name,
    required this.dosage,
    required this.scheduledAt,
  });

  final String name;
  final String dosage;
  final DateTime scheduledAt;

  int get timeInMinutes => (scheduledAt.hour * 60) + scheduledAt.minute;
}

class MedicationDeferredStartPreview {
  const MedicationDeferredStartPreview({
    required this.name,
    required this.dosage,
    required this.startsAt,
  });

  final String name;
  final String dosage;
  final DateTime startsAt;
}

class MedicationDaySummary {
  const MedicationDaySummary({
    required this.taken,
    required this.pending,
    required this.missed,
  });

  final int taken;
  final int pending;
  final int missed;

  int get total => taken + pending + missed;

  double get progress => total == 0 ? 0 : taken / total;
}

class MedsController extends ChangeNotifier {
  MedsController({
    required GetCachedMedicationsUseCase getCachedMedications,
    required GetMedicationsUseCase getMedications,
    required SaveMedicationUseCase saveMedication,
    required SetMedicationDailyStatusUseCase setMedicationDailyStatus,
    required DeleteMedicationUseCase deleteMedication,
    NotificationScheduler? notificationScheduler,
  }) : _getCachedMedications = getCachedMedications,
       _getMedications = getMedications,
       _saveMedication = saveMedication,
       _setMedicationDailyStatus = setMedicationDailyStatus,
       _deleteMedication = deleteMedication,
       _notificationScheduler =
           notificationScheduler ?? LocalNotificationsService.instance;

  final GetCachedMedicationsUseCase _getCachedMedications;
  final GetMedicationsUseCase _getMedications;
  final SaveMedicationUseCase _saveMedication;
  final SetMedicationDailyStatusUseCase _setMedicationDailyStatus;
  final DeleteMedicationUseCase _deleteMedication;
  final NotificationScheduler _notificationScheduler;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<Medication> _medications = const [];
  bool _initialized = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasMedications => _medications.isNotEmpty;
  List<Medication> get allMedications => List.unmodifiable(_medications);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await _loadCached();
    unawaited(refresh(showLoading: _medications.isEmpty));
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      _setMedications(await _getMedications());
      await _notificationScheduler.syncMedicationNotifications(_medications);
    } catch (_) {
      _errorMessage = 'Не удалось загрузить препараты.';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> saveMedication({
    Medication? existingMedication,
    required String name,
    required String dosage,
    required List<int> timesInMinutes,
    required MedicationFrequency frequency,
    required bool notificationsEnabled,
    required int selectedWeekday,
  }) async {
    final now = DateTime.now();
    final scheduledWeekdays = frequency == MedicationFrequency.weekly
        ? [_firstScheduledWeekday(existingMedication, selectedWeekday)]
        : List<int>.generate(7, (index) => index + 1);
    final dayStatuses = existingMedication?.dayStatuses ?? const {};

    final medication =
        existingMedication?.copyWith(
          name: name,
          dosage: dosage,
          frequency: frequency,
          timesInMinutes: _sortTimes(timesInMinutes),
          notificationsEnabled: notificationsEnabled,
          scheduledWeekdays: scheduledWeekdays,
          dayStatuses: dayStatuses,
          updatedAt: now,
        ) ??
        Medication(
          id: 'med-${now.microsecondsSinceEpoch}',
          name: name,
          dosage: dosage,
          frequency: frequency,
          timesInMinutes: _sortTimes(timesInMinutes),
          notificationsEnabled: notificationsEnabled,
          form: _resolveForm(name),
          scheduledWeekdays: scheduledWeekdays,
          dayStatuses: dayStatuses,
          createdAt: now,
          updatedAt: now,
        );

    await _persistMedication(
      previousMedications: _medications,
      nextMedications: _upsertMedication(_medications, medication),
      medication: medication,
      errorMessage: 'Не удалось сохранить препарат.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteMedication(Medication medication) async {
    _isSaving = true;
    _errorMessage = null;
    final previousMedications = _medications;
    _setMedications(
      _medications.where((item) => item.id != medication.id).toList(),
    );
    notifyListeners();

    try {
      await _deleteMedication(medication.id);
      await _notificationScheduler.cancelMedicationNotifications(medication.id);
      await _reloadFromCache();
    } catch (_) {
      _setMedications(previousMedications);
      _errorMessage = 'Не удалось удалить препарат.';
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(Medication medication) async {
    final updatedMedication = medication.copyWith(
      notificationsEnabled: !medication.notificationsEnabled,
      updatedAt: DateTime.now(),
    );

    await _persistMedication(
      previousMedications: _medications,
      nextMedications: _upsertMedication(_medications, updatedMedication),
      medication: updatedMedication,
      errorMessage: 'Не удалось обновить уведомления.',
    );
  }

  Future<void> toggleTakenStatus(
    Medication medication,
    DateTime selectedDate,
  ) async {
    final currentStatus = statusForDate(medication, selectedDate);
    if (currentStatus == null) {
      return;
    }

    final nextExplicitStatus = currentStatus == MedicationDayStatus.taken
        ? null
        : MedicationDayStatus.taken;
    final updatedMedication = medication.copyWithStatusForDate(
      selectedDate,
      nextExplicitStatus,
    );

    await _persistDailyStatus(
      previousMedications: _medications,
      nextMedications: _upsertMedication(_medications, updatedMedication),
      medicationId: medication.id,
      date: selectedDate,
      status: nextExplicitStatus,
      errorMessage: 'Не удалось обновить статус приема.',
    );
  }

  List<Medication> medicationsForDate(DateTime selectedDate) {
    return _medications
        .where((medication) => timesForDate(medication, selectedDate).isNotEmpty)
        .toList();
  }

  List<int> timesForDate(Medication medication, DateTime selectedDate) {
    return medication.visibleTimesForDate(selectedDate);
  }

  MedicationDayStatus? statusForDate(
    Medication medication,
    DateTime selectedDate, {
    DateTime? now,
  }) {
    final visibleTimes = timesForDate(medication, selectedDate);
    if (visibleTimes.isEmpty) {
      return null;
    }

    final explicitStatus = medication.explicitStatusForDate(selectedDate);
    if (explicitStatus == MedicationDayStatus.taken ||
        explicitStatus == MedicationDayStatus.missed) {
      return explicitStatus;
    }

    final referenceNow = now ?? DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final currentDay = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );

    if (selectedDay.isBefore(currentDay)) {
      return MedicationDayStatus.missed;
    }

    if (selectedDay.isAfter(currentDay)) {
      return MedicationDayStatus.pending;
    }

    final latestScheduledTime = visibleTimes.reduce(
      (left, right) => left > right ? left : right,
    );
    return _minutesOfDay(referenceNow) > latestScheduledTime
        ? MedicationDayStatus.missed
        : MedicationDayStatus.pending;
  }

  MedicationDaySummary summaryForDate(DateTime selectedDate) {
    var taken = 0;
    var pending = 0;
    var missed = 0;

    for (final medication in medicationsForDate(selectedDate)) {
      switch (statusForDate(medication, selectedDate)) {
        case MedicationDayStatus.taken:
          taken++;
        case MedicationDayStatus.pending:
          pending++;
        case MedicationDayStatus.missed:
          missed++;
        case null:
          break;
      }
    }

    return MedicationDaySummary(taken: taken, pending: pending, missed: missed);
  }

  List<MedicationReminderPreview> remindersForDate(DateTime selectedDate) {
    final referenceNow = DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final currentDay = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );

    if (selectedDay.isBefore(currentDay)) {
      return const [];
    }

    final reminders = medicationsForDate(selectedDate)
        .where(
          (medication) =>
              medication.notificationsEnabled &&
              statusForDate(medication, selectedDate, now: referenceNow) ==
                  MedicationDayStatus.pending,
        )
        .map((medication) {
          final reminderTime = _nextReminderTime(
            medication,
            selectedDate,
            referenceNow,
          );
          if (reminderTime == null) {
            return null;
          }

          return MedicationReminderPreview(
            name: medication.name,
            dosage: medication.dosage,
            scheduledAt: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              reminderTime ~/ 60,
              reminderTime % 60,
            ),
          );
        })
        .whereType<MedicationReminderPreview>()
        .toList()
      ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));

    return reminders;
  }

  Future<void> _loadCached() async {
    try {
      _setMedications(await _getCachedMedications());
      await _notificationScheduler.syncMedicationNotifications(_medications);
    } catch (_) {
      // Keep empty state if cache loading fails.
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistMedication({
    required List<Medication> previousMedications,
    required List<Medication> nextMedications,
    required Medication medication,
    required String errorMessage,
    bool rethrowOnFailure = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _setMedications(nextMedications);
    notifyListeners();

    try {
      await _saveMedication(medication);
      await _reloadFromCache();
    } catch (_) {
      _setMedications(previousMedications);
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

  Future<void> _persistDailyStatus({
    required List<Medication> previousMedications,
    required List<Medication> nextMedications,
    required String medicationId,
    required DateTime date,
    required MedicationDayStatus? status,
    required String errorMessage,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _setMedications(nextMedications);
    notifyListeners();

    try {
      await _setMedicationDailyStatus(medicationId, date, status);
      await _reloadFromCache();
    } catch (_) {
      _setMedications(previousMedications);
      _errorMessage = errorMessage;
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _reloadFromCache() async {
    _setMedications(await _getCachedMedications());
    await _notificationScheduler.syncMedicationNotifications(_medications);
  }

  int _firstScheduledWeekday(Medication? medication, int fallbackWeekday) {
    final scheduledWeekdays = medication?.scheduledWeekdays ?? const <int>[];
    if (scheduledWeekdays.isNotEmpty) {
      return scheduledWeekdays.first;
    }
    return fallbackWeekday;
  }

  List<int> _sortTimes(List<int> timesInMinutes) {
    final sorted = List<int>.from(timesInMinutes)..sort();
    return sorted;
  }

  List<Medication> _upsertMedication(
    List<Medication> source,
    Medication medication,
  ) {
    final updated = List<Medication>.from(source);
    final index = updated.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      updated.add(medication);
    } else {
      updated[index] = medication;
    }

    _sortInPlace(updated);
    return updated;
  }

  void _setMedications(List<Medication> medications) {
    _medications = List<Medication>.from(medications);
    _sortInPlace(_medications);
  }

  void _sortInPlace(List<Medication> medications) {
    medications.sort(
      (left, right) =>
          left.timesInMinutes.first.compareTo(right.timesInMinutes.first),
    );
  }

  int _minutesOfDay(DateTime dateTime) {
    return (dateTime.hour * 60) + dateTime.minute;
  }

  int? _nextReminderTime(
    Medication medication,
    DateTime selectedDate,
    DateTime referenceNow,
  ) {
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final currentDay = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );

    if (selectedDay.isBefore(currentDay)) {
      return null;
    }

    final sortedTimes = timesForDate(medication, selectedDate);
    if (sortedTimes.isEmpty) {
      return null;
    }

    if (selectedDay.isAfter(currentDay)) {
      return sortedTimes.first;
    }

    final currentMinutes = _minutesOfDay(referenceNow);
    for (final time in sortedTimes) {
      if (time > currentMinutes) {
        return time;
      }
    }

    return null;
  }

  MedicationForm _resolveForm(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('met') || normalized.contains('РјРµС‚')) {
      return MedicationForm.syringe;
    }
    if (normalized.contains('statin') || normalized.contains('СЃС‚Р°С‚РёРЅ')) {
      return MedicationForm.circle;
    }
    if (normalized.contains('pril') || normalized.contains('РїСЂРёР»')) {
      return MedicationForm.capsule;
    }
    return MedicationForm.tablet;
  }
}
