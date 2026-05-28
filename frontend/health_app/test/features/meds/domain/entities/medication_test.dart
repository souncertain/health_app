import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/meds/domain/entities/medication.dart';

import '../../../../support/test_data.dart';

void main() {
  group('Medication scheduling', () {
    test('isScheduledForWeekday checks scheduled weekdays', () {
      final medication = sampleMedication(scheduledWeekdays: const [1, 3, 5]);

      expect(medication.isScheduledForWeekday(DateTime.monday), isTrue);
      expect(medication.isScheduledForWeekday(DateTime.tuesday), isFalse);
    });

    test('isScheduledForDate returns false before created date', () {
      final medication = sampleMedication(createdAt: DateTime(2026, 5, 26, 9));

      final result = medication.isScheduledForDate(DateTime(2026, 5, 25));

      expect(result, isFalse);
    });

    test('dayAfterDay frequency schedules only every second day', () {
      final medication = sampleMedication(
        frequency: MedicationFrequency.dayAfterDay,
        createdAt: DateTime(2026, 5, 20, 9),
      );

      expect(medication.isScheduledForDate(DateTime(2026, 5, 20)), isTrue);
      expect(medication.isScheduledForDate(DateTime(2026, 5, 21)), isFalse);
      expect(medication.isScheduledForDate(DateTime(2026, 5, 22)), isTrue);
    });

    test('visibleTimesForDate returns empty list when date is not scheduled', () {
      final medication = sampleMedication(
        scheduledWeekdays: const [DateTime.monday],
      );

      final result = medication.visibleTimesForDate(DateTime(2026, 5, 26));

      expect(result, isEmpty);
    });

    test('visibleTimesForDate filters times earlier than creation time on same day', () {
      final medication = sampleMedication(
        createdAt: DateTime(2026, 5, 26, 12, 15),
        timesInMinutes: const [480, 720, 780],
      );

      final result = medication.visibleTimesForDate(DateTime(2026, 5, 26));

      expect(result, [780]);
    });

    test('visibleTimesForDate returns all sorted times on later dates', () {
      final medication = sampleMedication(
        createdAt: DateTime(2026, 5, 25, 12, 15),
        timesInMinutes: const [900, 480, 720],
      );

      final result = medication.visibleTimesForDate(DateTime(2026, 5, 26));

      expect(result, [480, 720, 900]);
    });

    test('wasCreatedAfterAllTimesForDate returns true when all times already passed', () {
      final medication = sampleMedication(
        createdAt: DateTime(2026, 5, 26, 18, 0),
        timesInMinutes: const [480, 720],
      );

      expect(medication.wasCreatedAfterAllTimesForDate(DateTime(2026, 5, 26)), isTrue);
    });

    test('nextReminderAt returns next future visible reminder', () {
      final medication = sampleMedication(
        createdAt: DateTime(2026, 5, 20, 9),
        timesInMinutes: const [600, 900],
      );

      final result = medication.nextReminderAt(
        after: DateTime(2026, 5, 26, 10, 1),
      );

      expect(result, DateTime(2026, 5, 26, 15, 0));
    });

    test('nextReminderAt skips dates marked as taken or missed', () {
      final date = DateTime(2026, 5, 26);
      final medication = sampleMedication(
        dayStatuses: {
          Medication.dateKey(date): MedicationDayStatus.taken,
        },
        timesInMinutes: const [600],
      );

      final result = medication.nextReminderAt(after: DateTime(2026, 5, 26, 9));

      expect(result, DateTime(2026, 5, 27, 10, 0));
    });
  });

  group('Medication statuses', () {
    test('explicitStatusForDate reads exact date key', () {
      final date = DateTime(2026, 5, 26);
      final medication = sampleMedication(
        dayStatuses: {
          Medication.dateKey(date): MedicationDayStatus.missed,
        },
      );

      expect(
        medication.explicitStatusForDate(date),
        MedicationDayStatus.missed,
      );
    });

    test('copyWithStatusForDate stores explicit status', () {
      final date = DateTime(2026, 5, 26);
      final medication = sampleMedication();

      final updated = medication.copyWithStatusForDate(
        date,
        MedicationDayStatus.taken,
      );

      expect(
        updated.dayStatuses[Medication.dateKey(date)],
        MedicationDayStatus.taken,
      );
    });

    test('copyWithStatusForDate removes explicit status when null is passed', () {
      final date = DateTime(2026, 5, 26);
      final medication = sampleMedication(
        dayStatuses: {
          Medication.dateKey(date): MedicationDayStatus.taken,
        },
      );

      final updated = medication.copyWithStatusForDate(date, null);

      expect(updated.dayStatuses, isEmpty);
    });
  });
}
