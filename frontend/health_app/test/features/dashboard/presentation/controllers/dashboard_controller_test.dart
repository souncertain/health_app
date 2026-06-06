import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/dashboard/domain/entities/blood_pressure_reading.dart';
import 'package:health_app/features/dashboard/domain/usecases/delete_blood_pressure_reading.dart';
import 'package:health_app/features/dashboard/domain/usecases/get_blood_pressure_readings.dart';
import 'package:health_app/features/dashboard/domain/usecases/save_blood_pressure_reading.dart';
import 'package:health_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockBloodPressureRepository repository;
  late DashboardController controller;

  setUp(() {
    repository = MockBloodPressureRepository();
    controller = DashboardController(
      getReadings: GetBloodPressureReadingsUseCase(repository),
      saveReading: SaveBloodPressureReadingUseCase(repository),
      deleteReading: DeleteBloodPressureReadingUseCase(repository),
    );
  });

  test('refresh loads readings sorted by recordedAt descending', () async {
    final older = sampleBloodPressureReading(
      id: 'older',
      recordedAt: DateTime(2026, 5, 25, 10),
    );
    final newer = sampleBloodPressureReading(
      id: 'newer',
      recordedAt: DateTime(2026, 5, 26, 10),
    );
    when(
      () => repository.getReadings(),
    ).thenAnswer((_) async => [older, newer]);

    await controller.refresh();

    expect(controller.allReadings.map((item) => item.id), ['newer', 'older']);
    expect(controller.latestReading?.id, 'newer');
  });

  test(
    'initialize does not refresh again when readings are already loaded',
    () async {
      when(
        () => repository.getReadings(),
      ).thenAnswer((_) async => [sampleBloodPressureReading()]);

      await controller.initialize();
      await controller.initialize();

      verify(() => repository.getReadings()).called(1);
    },
  );

  test('refresh sets error message when repository fails', () async {
    when(() => repository.getReadings()).thenThrow(Exception('boom'));

    await controller.refresh();

    expect(controller.errorMessage, isNotNull);
    expect(controller.isLoading, isFalse);
  });

  test('saveReading creates new reading and refreshes list', () async {
    when(() => repository.saveReading(any())).thenAnswer((_) async {});
    when(
      () => repository.getReadings(),
    ).thenAnswer((_) async => [sampleBloodPressureReading(systolic: 125)]);

    await controller.saveReading(
      systolic: 125,
      diastolic: 80,
      pulse: 70,
      recordedAt: sampleDateTime(),
    );

    verify(() => repository.saveReading(any())).called(1);
    expect(controller.allReadings.single.systolic, 125);
    expect(controller.isSaving, isFalse);
  });

  test(
    'saveReading rethrows and exposes error when persistence fails',
    () async {
      when(() => repository.saveReading(any())).thenThrow(Exception('boom'));

      await expectLater(
        controller.saveReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          recordedAt: sampleDateTime(),
        ),
        throwsException,
      );

      expect(controller.errorMessage, isNotNull);
      expect(controller.isSaving, isFalse);
    },
  );

  test(
    'deleteReading removes reading through repository and refreshes state',
    () async {
      final reading = sampleBloodPressureReading(id: 'bp-1');
      when(() => repository.deleteReading('bp-1')).thenAnswer((_) async {});
      when(() => repository.getReadings()).thenAnswer((_) async => const []);

      await controller.deleteReading(reading);

      verify(() => repository.deleteReading('bp-1')).called(1);
      expect(controller.allReadings, isEmpty);
    },
  );

  test(
    'averages and category counts are calculated from loaded readings',
    () async {
      when(() => repository.getReadings()).thenAnswer(
        (_) async => [
          sampleBloodPressureReading(systolic: 120, diastolic: 80, pulse: 60),
          sampleBloodPressureReading(systolic: 130, diastolic: 90, pulse: 80),
        ],
      );

      await controller.refresh();

      expect(controller.averageSystolic, 125);
      expect(controller.averageDiastolic, 85);
      expect(controller.averagePulse, 70);
      expect(controller.countByCategory(BloodPressureCategory.highStage1), 1);
    },
  );

  test(
    'readingsForRange falls back to reversed full list when nothing matches threshold',
    () async {
      final first = sampleBloodPressureReading(
        id: 'first',
        recordedAt: DateTime.now().subtract(const Duration(days: 90)),
      );
      final second = sampleBloodPressureReading(
        id: 'second',
        recordedAt: DateTime.now().subtract(const Duration(days: 80)),
      );
      when(
        () => repository.getReadings(),
      ).thenAnswer((_) async => [first, second]);

      await controller.refresh();
      final readings = controller.readingsForRange(
        DashboardHistoryRange.sevenDays,
      );

      expect(readings.map((item) => item.id), ['first', 'second']);
    },
  );
}
