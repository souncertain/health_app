enum MedicationFrequency {
  onceDaily,
  twiceDaily,
  threeTimesDaily,
  dayAfterDay,
  weekly,
}

enum MedicationForm { capsule, syringe, tablet, circle }

enum MedicationDayStatus { taken, pending, missed }

enum MedicationSyncState { localOnly, pendingUpload, synced }

class Medication {
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
  final Map<String, MedicationDayStatus> dayStatuses;
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
    Map<String, MedicationDayStatus>? dayStatuses,
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

  bool isScheduledForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    if (normalizedDate.isBefore(createdDate)) {
      return false;
    }

    if (frequency == MedicationFrequency.dayAfterDay) {
      return normalizedDate.difference(createdDate).inDays.isEven;
    }

    return isScheduledForWeekday(normalizedDate.weekday);
  }

  List<int> visibleTimesForDate(DateTime date) {
    if (!isScheduledForDate(date)) {
      return const [];
    }

    final sortedTimes = List<int>.from(timesInMinutes)..sort();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    if (normalizedDate != createdDate) {
      return sortedTimes;
    }

    final createdMinutes = (createdAt.hour * 60) + createdAt.minute;
    return sortedTimes.where((time) => time >= createdMinutes).toList();
  }

  bool wasCreatedAfterAllTimesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    if (normalizedDate != createdDate) {
      return false;
    }

    if (!isScheduledForDate(normalizedDate) || timesInMinutes.isEmpty) {
      return false;
    }

    return visibleTimesForDate(normalizedDate).isEmpty;
  }

  DateTime? nextReminderAt({
    DateTime? after,
    int searchDays = 14,
  }) {
    final referenceAfter = after ?? DateTime.now();
    final startDate = DateTime(
      referenceAfter.year,
      referenceAfter.month,
      referenceAfter.day,
    );

    for (var offset = 0; offset <= searchDays; offset++) {
      final candidateDate = startDate.add(Duration(days: offset));
      if (!isScheduledForDate(candidateDate)) {
        continue;
      }

      final explicitStatus = explicitStatusForDate(candidateDate);
      if (explicitStatus == MedicationDayStatus.taken ||
          explicitStatus == MedicationDayStatus.missed) {
        continue;
      }

      final availableTimes = visibleTimesForDate(candidateDate);
      for (final time in availableTimes) {
        final scheduledAt = DateTime(
          candidateDate.year,
          candidateDate.month,
          candidateDate.day,
          time ~/ 60,
          time % 60,
        );
        if (scheduledAt.isAfter(referenceAfter)) {
          return scheduledAt;
        }
      }
    }

    return null;
  }

  MedicationDayStatus? explicitStatusForDate(DateTime date) {
    return dayStatuses[_dateKey(date)];
  }

  Medication copyWithStatusForDate(DateTime date, MedicationDayStatus? status) {
    final nextStatuses = Map<String, MedicationDayStatus>.from(dayStatuses);
    final key = _dateKey(date);
    if (status == null) {
      nextStatuses.remove(key);
    } else {
      nextStatuses[key] = status;
    }

    return copyWith(dayStatuses: nextStatuses);
  }

  MedicationDayStatus? statusForWeekday(int weekday) {
    if (!isScheduledForWeekday(weekday)) {
      return null;
    }
    return MedicationDayStatus.pending;
  }

  static String dateKey(DateTime date) => _dateKey(date);

  static String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
