import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/dashboard/data/models/blood_pressure_reading_model.dart';
import 'package:health_app/features/dashboard/domain/entities/blood_pressure_reading.dart';
import 'package:health_app/features/meds/data/models/medication_model.dart';
import 'package:health_app/features/metrics/data/models/health_metric_model.dart';
import 'package:health_app/features/profile/domain/entities/profile_stats_snapshot.dart';
import 'package:health_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:health_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:health_app/features/visits/data/models/medical_visit_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockProfileRepository repository;
  late MockNotificationScheduler notifications;
  late MockBloodPressureLocalDataSource bloodPressureLocalDataSource;
  late MockMedicationLocalDataSource medicationLocalDataSource;
  late MockHealthMetricsLocalDataSource healthMetricsLocalDataSource;
  late MockMedicalVisitsLocalDataSource medicalVisitsLocalDataSource;

  late ProfileController controller;

  setUp(() {
    repository = MockProfileRepository();
    notifications = MockNotificationScheduler();
    bloodPressureLocalDataSource = MockBloodPressureLocalDataSource();
    medicationLocalDataSource = MockMedicationLocalDataSource();
    healthMetricsLocalDataSource = MockHealthMetricsLocalDataSource();
    medicalVisitsLocalDataSource = MockMedicalVisitsLocalDataSource();

    when(() => notifications.syncMedicationNotifications(any()))
        .thenAnswer((_) async {});
    when(() => notifications.syncVisitNotifications(any()))
        .thenAnswer((_) async {});
    when(() => notifications.cancelAllNotifications()).thenAnswer((_) async {});

    controller = ProfileController(
      repository: repository,
      notifications: notifications,
      bloodPressureLocalDataSource: bloodPressureLocalDataSource,
      medicationLocalDataSource: medicationLocalDataSource,
      healthMetricsLocalDataSource: healthMetricsLocalDataSource,
      medicalVisitsLocalDataSource: medicalVisitsLocalDataSource,
    );
  });

  test('refresh uses repository stats snapshot when repository supports it', () async {
    when(() => repository.getProfile()).thenAnswer(
      (_) async => sampleUserProfile(fullName: 'Remote User'),
    );
    when(() => repository.getProfileStats()).thenAnswer(
      (_) async => const ProfileStatsSnapshot(
        bloodPressureReadingsCount: 5,
        medicationsCount: 2,
        appointmentsCount: 1,
        daysTracked: 7,
      ),
    );

    await controller.refresh();

    expect(controller.profile.fullName, 'Remote User');
    expect(controller.stats.bpReadingsCount, 5);
    expect(controller.stats.medicationsCount, 2);
  });

  test('refresh builds local stats when repository does not support stats interface', () async {
    final plainRepository = _PlainProfileRepository();
    when(() => plainRepository.getProfile()).thenAnswer(
      (_) async => sampleUserProfile(fullName: 'Local User'),
    );
    when(() => plainRepository.getCachedProfile()).thenAnswer((_) async => null);
    when(() => bloodPressureLocalDataSource.getReadings()).thenAnswer(
      (_) async => [
        BloodPressureReadingModel.fromEntity(
          sampleBloodPressureReading(
            syncState: BloodPressureSyncState.pendingDelete,
          ),
        ),
        BloodPressureReadingModel.fromEntity(
          sampleBloodPressureReading(
            syncState: BloodPressureSyncState.synced,
          ),
        ),
      ],
    );
    when(() => medicationLocalDataSource.getMedications()).thenAnswer(
      (_) async => [MedicationModel.fromEntity(sampleMedication())],
    );
    when(() => healthMetricsLocalDataSource.getMetrics()).thenAnswer(
      (_) async => [
        HealthMetricModel.fromEntity(
          sampleHealthMetric(records: [sampleMetricRecord(value: 5)]),
        ),
      ],
    );
    when(() => medicalVisitsLocalDataSource.getVisits()).thenAnswer(
      (_) async => [MedicalVisitModel.fromEntity(sampleMedicalVisit())],
    );
    final localController = ProfileController(
      repository: plainRepository,
      notifications: notifications,
      bloodPressureLocalDataSource: bloodPressureLocalDataSource,
      medicationLocalDataSource: medicationLocalDataSource,
      healthMetricsLocalDataSource: healthMetricsLocalDataSource,
      medicalVisitsLocalDataSource: medicalVisitsLocalDataSource,
    );

    await localController.refresh();

    expect(localController.stats.bpReadingsCount, 1);
    expect(localController.stats.medicationsCount, 1);
    expect(localController.stats.appointmentsCount, 1);
    expect(localController.stats.daysTracked, greaterThanOrEqualTo(1));
  });

  test('saveProfile persists profile and refreshes snapshot stats', () async {
    final profile = sampleUserProfile(fullName: 'Updated User');
    when(() => repository.saveProfile(profile)).thenAnswer((_) async {});
    when(() => repository.getCachedProfile()).thenAnswer((_) async => profile);
    when(() => repository.getProfileStats()).thenAnswer(
      (_) async => sampleProfileStatsSnapshot(daysTracked: 12),
    );

    await controller.saveProfile(profile);

    expect(controller.profile.fullName, 'Updated User');
    expect(controller.stats.daysTracked, 12);
  });

  test('saveProfile reverts optimistic profile when persistence fails', () async {
    final original = sampleUserProfile(fullName: 'Original');
    when(() => repository.getProfile()).thenAnswer((_) async => original);
    when(() => repository.getCachedProfile()).thenAnswer((_) async => original);
    when(() => repository.getProfileStats()).thenAnswer(
      (_) async => sampleProfileStatsSnapshot(),
    );
    await controller.refresh();

    final updated = sampleUserProfile(fullName: 'Updated');
    when(() => repository.saveProfile(updated)).thenThrow(Exception('boom'));

    await expectLater(controller.saveProfile(updated), throwsException);

    expect(controller.profile.fullName, 'Original');
  });

  test('toggleNotifications cancels all notifications when disabling them', () async {
    final profile = sampleUserProfile(notificationsEnabled: true);
    when(() => repository.getProfile()).thenAnswer((_) async => profile);
    when(() => repository.getCachedProfile()).thenAnswer((_) async => profile);
    when(() => repository.getProfileStats()).thenAnswer(
      (_) async => sampleProfileStatsSnapshot(),
    );
    when(() => repository.saveProfile(any())).thenAnswer((_) async {});
    await controller.refresh();

    await controller.toggleNotifications(false);

    verify(() => notifications.cancelAllNotifications()).called(1);
  });

  test('toggleNotifications syncs medication and visit notifications when enabling them', () async {
    final profile = sampleUserProfile(notificationsEnabled: false);
    when(() => repository.getProfile()).thenAnswer((_) async => profile);
    when(() => repository.getCachedProfile()).thenAnswer(
      (_) async => profile.copyWith(notificationsEnabled: true),
    );
    when(() => repository.getProfileStats()).thenAnswer(
      (_) async => sampleProfileStatsSnapshot(),
    );
    when(() => repository.saveProfile(any())).thenAnswer((_) async {});
    when(() => medicationLocalDataSource.getMedications()).thenAnswer(
      (_) async => [MedicationModel.fromEntity(sampleMedication())],
    );
    when(() => medicalVisitsLocalDataSource.getVisits()).thenAnswer(
      (_) async => [MedicalVisitModel.fromEntity(sampleMedicalVisit())],
    );
    await controller.refresh();

    await controller.toggleNotifications(true);

    verify(() => notifications.syncMedicationNotifications(any())).called(1);
    verify(() => notifications.syncVisitNotifications(any())).called(1);
  });
}

class _PlainProfileRepository extends Mock implements ProfileRepository {}
