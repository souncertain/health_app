import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/dashboard/data/datasources/blood_pressure_local_data_source.dart';
import 'package:health_app/features/dashboard/data/models/blood_pressure_reading_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/test_data.dart';

void main() {
  late BloodPressureLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = BloodPressureLocalDataSource();
  });

  test('getReadings returns empty list when storage is empty', () async {
    expect(await dataSource.getReadings(), isEmpty);
  });

  test('saveAll persists readings and getReadings restores them', () async {
    final readings = [
      BloodPressureReadingModel.fromEntity(
        sampleBloodPressureReading(id: 'bp-1', systolic: 123),
      ),
    ];

    await dataSource.saveAll(readings);

    final restored = await dataSource.getReadings();
    expect(restored.single.id, 'bp-1');
    expect(restored.single.systolic, 123);
  });

  test('clear removes stored readings', () async {
    await dataSource.saveAll([
      BloodPressureReadingModel.fromEntity(sampleBloodPressureReading()),
    ]);

    await dataSource.clear();

    expect(await dataSource.getReadings(), isEmpty);
  });
}
