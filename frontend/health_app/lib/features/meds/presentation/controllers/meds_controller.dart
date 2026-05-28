import '../../../../core/controllers/cache_first_collection_controller.dart';
import '../../../../core/services/local_notifications_service.dart';
import '../../../../core/utils/collection_extensions.dart';
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

class MedsController extends CacheFirstCollectionController<Medication> {
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

  bool get hasMedications => currentItems.isNotEmpty;
  List<Medication> get allMedications => List.unmodifiable(currentItems);

  @override
  String get refreshErrorMessage =>
      'РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РіСЂСѓР·РёС‚СЊ РїСЂРµРїР°СЂР°С‚С‹.';

  @override
  Future<List<Medication>> loadCachedItems() => _getCachedMedications();

  @override
  Future<List<Medication>> loadRemoteItems() => _getMedications();

  @override
  List<Medication> sortItems(List<Medication> items) {
    final sorted = List<Medication>.from(items);
    _sortInPlace(sorted);
    return sorted;
  }

  @override
  Future<void> onItemsUpdated(List<Medication> items) {
    return _notificationScheduler.syncMedicationNotifications(items);
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

    await runOptimisticMutation(
      nextItems: _upsertMedication(currentItems, medication),
      action: () => _saveMedication(medication),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕС…СЂР°РЅРёС‚СЊ РїСЂРµРїР°СЂР°С‚.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteMedication(Medication medication) async {
    await runOptimisticMutation(
      nextItems: currentItems.where((item) => item.id != medication.id).toList(),
      action: () async {
        await _deleteMedication(medication.id);
        await _notificationScheduler.cancelMedicationNotifications(
          medication.id,
        );
      },
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ РїСЂРµРїР°СЂР°С‚.',
      rethrowOnFailure: true,
    );
  }

  Future<void> toggleNotifications(Medication medication) async {
    final updatedMedication = medication.copyWith(
      notificationsEnabled: !medication.notificationsEnabled,
      updatedAt: DateTime.now(),
    );

    await runOptimisticMutation(
      nextItems: _upsertMedication(currentItems, updatedMedication),
      action: () => _saveMedication(updatedMedication),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёСЏ.',
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

    await runOptimisticMutation(
      nextItems: _upsertMedication(currentItems, updatedMedication),
      action: () => _setMedicationDailyStatus(
        medication.id,
        selectedDate,
        nextExplicitStatus,
      ),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ СЃС‚Р°С‚СѓСЃ РїСЂРёРµРјР°.',
    );
  }

  List<Medication> medicationsForDate(DateTime selectedDate) {
    return currentItems
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
    updated.upsertWhere(medication, (item) => item.id == medication.id);
    _sortInPlace(updated);
    return updated;
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
    if (normalized.contains('met') || normalized.contains('Р СР ВµРЎвЂљ')) {
      return MedicationForm.syringe;
    }
    if (normalized.contains('statin') ||
        normalized.contains('РЎРѓРЎвЂљР В°РЎвЂљР С‘Р Р…')) {
      return MedicationForm.circle;
    }
    if (normalized.contains('pril') || normalized.contains('Р С—РЎР‚Р С‘Р В»')) {
      return MedicationForm.capsule;
    }
    return MedicationForm.tablet;
  }
}
