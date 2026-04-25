import 'package:flutter/foundation.dart';

import '../../domain/entities/medication.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/save_medication.dart';

class MedicationReminderPreview {
  const MedicationReminderPreview({
    required this.name,
    required this.dosage,
    required this.timeInMinutes,
  });

  final String name;
  final String dosage;
  final int timeInMinutes;
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
    required GetMedicationsUseCase getMedications,
    required SaveMedicationUseCase saveMedication,
    required DeleteMedicationUseCase deleteMedication,
  }) : _getMedications = getMedications,
       _saveMedication = saveMedication,
       _deleteMedication = deleteMedication;

  final GetMedicationsUseCase _getMedications;
  final SaveMedicationUseCase _saveMedication;
  final DeleteMedicationUseCase _deleteMedication;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<Medication> _medications = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasMedications => _medications.isNotEmpty;
  List<Medication> get allMedications => List.unmodifiable(_medications);

  Future<void> initialize() async {
    if (_isLoading || _medications.isNotEmpty) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final medications = await _getMedications();
      _medications = List<Medication>.from(medications)
        ..sort(
          (left, right) =>
              left.timesInMinutes.first.compareTo(right.timesInMinutes.first),
        );
    } catch (_) {
      _errorMessage = 'Could not load medications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveMedication({
    Medication? existingMedication,
    required String name,
    required String dosage,
    required int baseTimeInMinutes,
    required MedicationFrequency frequency,
    required bool notificationsEnabled,
    required int selectedWeekday,
  }) async {
    final now = DateTime.now();
    final scheduledWeekdays = frequency == MedicationFrequency.weekly
        ? [_firstScheduledWeekday(existingMedication, selectedWeekday)]
        : List<int>.generate(7, (index) => index + 1);
    final dayStatuses = _mergeStatuses(
      existing: existingMedication?.dayStatuses ?? const {},
      scheduledWeekdays: scheduledWeekdays,
      selectedWeekday: selectedWeekday,
    );

    final medication =
        existingMedication?.copyWith(
          name: name,
          dosage: dosage,
          frequency: frequency,
          timesInMinutes: _buildTimes(baseTimeInMinutes, frequency),
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
          timesInMinutes: _buildTimes(baseTimeInMinutes, frequency),
          notificationsEnabled: notificationsEnabled,
          form: _resolveForm(name),
          scheduledWeekdays: scheduledWeekdays,
          dayStatuses: dayStatuses,
          createdAt: now,
          updatedAt: now,
        );

    await _persistMedication(
      medication,
      errorMessage: 'Could not save the medication.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteMedication(Medication medication) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteMedication(medication.id);
      await refresh();
    } catch (_) {
      _errorMessage = 'Could not delete the medication.';
      _isSaving = false;
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(Medication medication) async {
    await _persistMedication(
      medication.copyWith(
        notificationsEnabled: !medication.notificationsEnabled,
        updatedAt: DateTime.now(),
      ),
      errorMessage: 'Could not update notifications.',
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

    final weekday = selectedDate.weekday;
    final nextStatuses =
        Map<int, MedicationDayStatus>.from(medication.dayStatuses)
          ..[weekday] = currentStatus == MedicationDayStatus.taken
              ? MedicationDayStatus.pending
              : MedicationDayStatus.taken;

    await _persistMedication(
      medication.copyWith(dayStatuses: nextStatuses, updatedAt: DateTime.now()),
      errorMessage: 'Could not update the medication status.',
    );
  }

  List<Medication> medicationsForWeekday(int weekday) {
    return _medications
        .where((medication) => medication.isScheduledForWeekday(weekday))
        .toList();
  }

  List<Medication> medicationsForDate(DateTime selectedDate) {
    return medicationsForWeekday(selectedDate.weekday);
  }

  MedicationDayStatus? statusForDate(
    Medication medication,
    DateTime selectedDate, {
    DateTime? now,
  }) {
    if (!medication.isScheduledForWeekday(selectedDate.weekday)) {
      return null;
    }

    final storedStatus =
        medication.dayStatuses[selectedDate.weekday] ??
        MedicationDayStatus.pending;

    if (storedStatus == MedicationDayStatus.taken ||
        storedStatus == MedicationDayStatus.missed) {
      return storedStatus;
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

    final latestScheduledTime = medication.timesInMinutes.reduce(
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
    final reminders =
        medicationsForDate(selectedDate)
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
                timeInMinutes: reminderTime,
              );
            })
            .whereType<MedicationReminderPreview>()
            .toList()
          ..sort(
            (left, right) => left.timeInMinutes.compareTo(right.timeInMinutes),
          );

    return reminders;
  }

  Future<void> _persistMedication(
    Medication medication, {
    required String errorMessage,
    bool rethrowOnFailure = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _saveMedication(medication);
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

  int _firstScheduledWeekday(Medication? medication, int fallbackWeekday) {
    final scheduledWeekdays = medication?.scheduledWeekdays ?? const <int>[];
    if (scheduledWeekdays.isNotEmpty) {
      return scheduledWeekdays.first;
    }
    return fallbackWeekday;
  }

  Map<int, MedicationDayStatus> _mergeStatuses({
    required Map<int, MedicationDayStatus> existing,
    required List<int> scheduledWeekdays,
    required int selectedWeekday,
  }) {
    final next = <int, MedicationDayStatus>{};
    for (final weekday in scheduledWeekdays) {
      next[weekday] =
          existing[weekday] ??
          (weekday == selectedWeekday
              ? MedicationDayStatus.pending
              : MedicationDayStatus.pending);
    }
    return next;
  }

  List<int> _buildTimes(int baseTimeInMinutes, MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.onceDaily:
      case MedicationFrequency.weekly:
        return [baseTimeInMinutes];
      case MedicationFrequency.twiceDaily:
        return [
          baseTimeInMinutes,
          _normalizeMinutes(baseTimeInMinutes + (12 * 60)),
        ];
      case MedicationFrequency.threeTimesDaily:
        return [
          baseTimeInMinutes,
          _normalizeMinutes(baseTimeInMinutes + (8 * 60)),
          _normalizeMinutes(baseTimeInMinutes + (16 * 60)),
        ];
    }
  }

  int _normalizeMinutes(int minutes) {
    const minutesPerDay = 24 * 60;
    final normalized = minutes % minutesPerDay;
    return normalized < 0 ? normalized + minutesPerDay : normalized;
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

    final sortedTimes = List<int>.from(medication.timesInMinutes)..sort();
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

  int _minutesOfDay(DateTime dateTime) {
    return (dateTime.hour * 60) + dateTime.minute;
  }

  MedicationForm _resolveForm(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('met')) {
      return MedicationForm.syringe;
    }
    if (normalized.contains('statin')) {
      return MedicationForm.circle;
    }
    if (normalized.contains('pril')) {
      return MedicationForm.capsule;
    }
    return MedicationForm.tablet;
  }
}
