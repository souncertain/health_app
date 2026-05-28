import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/meds/domain/entities/medication.dart';
import 'package:health_app/features/meds/domain/usecases/delete_medication.dart';
import 'package:health_app/features/meds/domain/usecases/get_cached_medications.dart';
import 'package:health_app/features/meds/domain/usecases/get_medications.dart';
import 'package:health_app/features/meds/domain/usecases/save_medication.dart';
import 'package:health_app/features/meds/domain/usecases/set_medication_daily_status.dart';
import 'package:health_app/features/meds/presentation/controllers/meds_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockMedicationRepository repository;
  late MockNotificationScheduler notificationScheduler;
  late MedsController controller;

  setUp(() {
    repository = MockMedicationRepository();
    notificationScheduler = MockNotificationScheduler();
    when(() => repository.getCachedMedications()).thenAnswer((_) async => const []);
    when(() => repository.getMedications()).thenAnswer((_) async => const []);
    when(() => notificationScheduler.syncMedicationNotifications(any()))
        .thenAnswer((_) async {});
    when(() => notificationScheduler.cancelMedicationNotifications(any()))
        .thenAnswer((_) async {});

    controller = MedsController(
      getCachedMedications: GetCachedMedicationsUseCase(repository),
      getMedications: GetMedicationsUseCase(repository),
      saveMedication: SaveMedicationUseCase(repository),
      setMedicationDailyStatus: SetMedicationDailyStatusUseCase(repository),
      deleteMedication: DeleteMedicationUseCase(repository),
      notificationScheduler: notificationScheduler,
    );
  });

  Future<void> seedMedications(List<Medication> medications) async {
    when(() => repository.getCachedMedications()).thenAnswer((_) async => medications);
    when(() => repository.getMedications()).thenAnswer((_) async => medications);
    await controller.initialize();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('saveMedication creates weekday schedule for non-weekly frequencies', () async {
    when(() => repository.saveMedication(any())).thenAnswer((_) async {});

    await controller.saveMedication(
      name: 'Aspirin',
      dosage: '10 mg',
      timesInMinutes: const [900, 480],
      frequency: MedicationFrequency.twiceDaily,
      notificationsEnabled: true,
      selectedWeekday: DateTime.tuesday,
    );

    final captured =
        verify(() => repository.saveMedication(captureAny())).captured.single
            as Medication;
    expect(captured.timesInMinutes, [480, 900]);
    expect(captured.scheduledWeekdays, [1, 2, 3, 4, 5, 6, 7]);
  });

  test('saveMedication uses only selected weekday for weekly frequency', () async {
    when(() => repository.saveMedication(any())).thenAnswer((_) async {});

    await controller.saveMedication(
      name: 'Aspirin',
      dosage: '10 mg',
      timesInMinutes: const [480],
      frequency: MedicationFrequency.weekly,
      notificationsEnabled: true,
      selectedWeekday: DateTime.friday,
    );

    final captured =
        verify(() => repository.saveMedication(captureAny())).captured.single
            as Medication;
    expect(captured.scheduledWeekdays, [DateTime.friday]);
  });

  test('statusForDate returns explicit taken status when set', () async {
    final date = DateTime(2026, 5, 26);
    final medication = sampleMedication(
      createdAt: DateTime(2026, 5, 20),
      dayStatuses: {
        Medication.dateKey(date): MedicationDayStatus.taken,
      },
    );

    final status = controller.statusForDate(medication, date);

    expect(status, MedicationDayStatus.taken);
  });

  test('statusForDate returns missed for past scheduled day', () async {
    final medication = sampleMedication(createdAt: DateTime(2026, 5, 1));

    final status = controller.statusForDate(medication, DateTime(2026, 5, 20));

    expect(status, MedicationDayStatus.missed);
  });

  test('statusForDate returns pending for future scheduled day', () async {
    final medication = sampleMedication();

    final status = controller.statusForDate(
      medication,
      DateTime.now().add(const Duration(days: 1)),
    );

    expect(status, MedicationDayStatus.pending);
  });

  test('summaryForDate counts taken pending and missed medications', () async {
    final selectedDate = DateTime.now().add(const Duration(days: 1));
    final taken = sampleMedication(
      id: 'taken',
      createdAt: selectedDate.subtract(const Duration(days: 6)),
      dayStatuses: {
        Medication.dateKey(selectedDate): MedicationDayStatus.taken,
      },
    );
    final pending = sampleMedication(
      id: 'pending',
      createdAt: selectedDate.subtract(const Duration(days: 6)),
      timesInMinutes: const [23 * 60 + 59],
    );
    final missed = sampleMedication(
      id: 'missed',
      createdAt: selectedDate.subtract(const Duration(days: 6)),
      dayStatuses: {
        Medication.dateKey(selectedDate): MedicationDayStatus.missed,
      },
    );
    await seedMedications([taken, pending, missed]);

    final summary = controller.summaryForDate(selectedDate);

    expect(summary.taken, 1);
    expect(summary.pending, 1);
    expect(summary.missed, 1);
    expect(summary.total, 3);
  });

  test('remindersForDate returns only upcoming reminders in chronological order', () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final later = sampleMedication(
      id: 'later',
      name: 'later',
      createdAt: DateTime(2026, 5, 20),
      timesInMinutes: const [900],
    );
    final sooner = sampleMedication(
      id: 'sooner',
      name: 'sooner',
      createdAt: DateTime(2026, 5, 20),
      timesInMinutes: const [600],
    );
    await seedMedications([later, sooner]);

    final reminders = controller.remindersForDate(tomorrow);

    expect(reminders.map((item) => item.name), ['sooner', 'later']);
  });

  test('toggleTakenStatus updates repository when medication is visible for date', () async {
    final date = DateTime.now().add(const Duration(days: 1));
    final medication = sampleMedication(
      createdAt: date.subtract(const Duration(days: 6)),
    );
    await seedMedications([medication]);
    when(
      () => repository.setMedicationDailyStatus(
        medication.id,
        date,
        MedicationDayStatus.taken,
      ),
    ).thenAnswer((_) async {});

    await controller.toggleTakenStatus(medication, date);

    verify(
      () => repository.setMedicationDailyStatus(
        medication.id,
        date,
        MedicationDayStatus.taken,
      ),
    ).called(1);
  });

  test('toggleNotifications updates medication and persists it', () async {
    final medication = sampleMedication(notificationsEnabled: true);
    await seedMedications([medication]);
    when(() => repository.saveMedication(any())).thenAnswer((_) async {});

    await controller.toggleNotifications(medication);

    final captured =
        verify(() => repository.saveMedication(captureAny())).captured.single
            as Medication;
    expect(captured.notificationsEnabled, isFalse);
  });

  test('deleteMedication removes medication and cancels notifications', () async {
    final medication = sampleMedication(id: 'med-1');
    await seedMedications([medication]);
    when(() => repository.deleteMedication('med-1')).thenAnswer((_) async {});

    await controller.deleteMedication(medication);

    verify(() => repository.deleteMedication('med-1')).called(1);
    verify(() => notificationScheduler.cancelMedicationNotifications('med-1'))
        .called(1);
  });
}
