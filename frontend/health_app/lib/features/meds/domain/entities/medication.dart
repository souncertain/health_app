enum MedicationFrequency { onceDaily, twiceDaily, threeTimesDaily, weekly }

enum MedicationForm { capsule, syringe, tablet, circle }

enum MedicationDayStatus { taken, pending, missed }

enum MedicationSyncState { localOnly, pendingUpload, synced }

class Medication { // TODO Add DayAfterDay 
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timesInMinutes,
    required this.notificationsEnabled,
    required this.form,
    required this.scheduledWeekdays,
    required this.dayStatuses,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncState = MedicationSyncState.localOnly,
  });

  final String id;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final List<int> timesInMinutes;
  final bool notificationsEnabled;
  final MedicationForm form;
  final List<int> scheduledWeekdays;
  final Map<int, MedicationDayStatus> dayStatuses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final MedicationSyncState syncState;

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    MedicationFrequency? frequency,
    List<int>? timesInMinutes,
    bool? notificationsEnabled,
    MedicationForm? form,
    List<int>? scheduledWeekdays,
    Map<int, MedicationDayStatus>? dayStatuses,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    MedicationSyncState? syncState,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timesInMinutes: timesInMinutes ?? this.timesInMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      form: form ?? this.form,
      scheduledWeekdays: scheduledWeekdays ?? this.scheduledWeekdays,
      dayStatuses: dayStatuses ?? this.dayStatuses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncState: syncState ?? this.syncState,
    );
  }

  bool isScheduledForWeekday(int weekday) {
    return scheduledWeekdays.contains(weekday);
  }

  MedicationDayStatus? statusForWeekday(int weekday) {
    if (!isScheduledForWeekday(weekday)) {
      return null;
    }
    return dayStatuses[weekday] ?? MedicationDayStatus.pending;
  }
}
