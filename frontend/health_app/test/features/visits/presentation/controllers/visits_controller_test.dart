import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/visits/domain/entities/medical_visit.dart';
import 'package:health_app/features/visits/domain/usecases/delete_medical_visit.dart';
import 'package:health_app/features/visits/domain/usecases/get_cached_medical_visits.dart';
import 'package:health_app/features/visits/domain/usecases/get_medical_visits.dart';
import 'package:health_app/features/visits/domain/usecases/save_medical_visit.dart';
import 'package:health_app/features/visits/presentation/controllers/visits_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockMedicalVisitRepository repository;
  late MockNotificationScheduler notificationScheduler;
  late VisitsController controller;

  setUp(() {
    repository = MockMedicalVisitRepository();
    notificationScheduler = MockNotificationScheduler();
    when(() => repository.getCachedVisits()).thenAnswer((_) async => const []);
    when(() => repository.getVisits()).thenAnswer((_) async => const []);
    when(() => notificationScheduler.syncVisitNotifications(any()))
        .thenAnswer((_) async {});
    when(() => notificationScheduler.cancelVisitNotification(any()))
        .thenAnswer((_) async {});

    controller = VisitsController(
      getCachedVisits: GetCachedMedicalVisitsUseCase(repository),
      getVisits: GetMedicalVisitsUseCase(repository),
      saveVisit: SaveMedicalVisitUseCase(repository),
      deleteVisit: DeleteMedicalVisitUseCase(repository),
      notificationScheduler: notificationScheduler,
    );
  });

  Future<void> seedVisits(List<MedicalVisit> visits) async {
    when(() => repository.getCachedVisits()).thenAnswer((_) async => visits);
    when(() => repository.getVisits()).thenAnswer((_) async => visits);
    await controller.initialize();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('visitsForType filters by type and sorts by scheduledAt', () async {
    final early = sampleMedicalVisit(
      id: 'early',
      visitType: MedicalVisitType.oneTime,
      appointmentDate: DateTime(2026, 5, 26),
      timeInMinutes: 500,
    );
    final late = sampleMedicalVisit(
      id: 'late',
      visitType: MedicalVisitType.oneTime,
      appointmentDate: DateTime(2026, 5, 26),
      timeInMinutes: 700,
    );
    final recurring = sampleMedicalVisit(
      id: 'rec',
      visitType: MedicalVisitType.recurring,
    );
    await seedVisits([late, recurring, early]);

    final visits = controller.visitsForType(MedicalVisitType.oneTime);

    expect(visits.map((item) => item.id), ['early', 'late']);
  });

  test('nextVisitForType returns upcoming visit when available', () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final upcoming = sampleMedicalVisit(
      id: 'upcoming',
      appointmentDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
    await seedVisits([upcoming]);

    final visit = controller.nextVisitForType(MedicalVisitType.oneTime);

    expect(visit?.id, 'upcoming');
  });

  test('nextVisitForType falls back to first visit when all are in the past', () async {
    final past = sampleMedicalVisit(
      id: 'past',
      appointmentDate: DateTime.now().subtract(const Duration(days: 5)),
    );
    await seedVisits([past]);

    final visit = controller.nextVisitForType(MedicalVisitType.oneTime);

    expect(visit?.id, 'past');
  });

  test('saveVisit creates one-time visit with normalized date and rating 4.9', () async {
    when(() => repository.saveVisit(any())).thenAnswer((_) async {});

    await controller.saveVisit(
      doctorName: 'Doctor',
      specialty: 'Cardiology',
      appointmentDate: DateTime(2026, 5, 26, 15),
      timeInMinutes: 600,
      location: 'Clinic',
      visitType: MedicalVisitType.oneTime,
    );

    final captured =
        verify(() => repository.saveVisit(captureAny())).captured.single
            as MedicalVisit;
    expect(captured.rating, 4.9);
    expect(captured.appointmentDate, DateTime(2026, 5, 26));
  });

  test('saveVisit creates recurring visit with rating 4.8', () async {
    when(() => repository.saveVisit(any())).thenAnswer((_) async {});

    await controller.saveVisit(
      doctorName: 'Doctor',
      specialty: 'Therapy',
      appointmentDate: DateTime(2026, 5, 26),
      timeInMinutes: 600,
      location: 'Clinic',
      visitType: MedicalVisitType.recurring,
    );

    final captured =
        verify(() => repository.saveVisit(captureAny())).captured.single
            as MedicalVisit;
    expect(captured.rating, 4.8);
  });

  test('rescheduleVisit updates visit time and persists it', () async {
    final visit = sampleMedicalVisit(timeInMinutes: 540);
    await seedVisits([visit]);
    when(() => repository.saveVisit(any())).thenAnswer((_) async {});

    await controller.rescheduleVisit(visit, 600);

    final captured =
        verify(() => repository.saveVisit(captureAny())).captured.single
            as MedicalVisit;
    expect(captured.timeInMinutes, 600);
  });

  test('deleteVisit removes visit and cancels notification', () async {
    final visit = sampleMedicalVisit(id: 'visit-1');
    await seedVisits([visit]);
    when(() => repository.deleteVisit('visit-1')).thenAnswer((_) async {});

    await controller.deleteVisit(visit);

    verify(() => repository.deleteVisit('visit-1')).called(1);
    verify(() => notificationScheduler.cancelVisitNotification('visit-1'))
        .called(1);
  });
}
