import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/dashboard/domain/entities/blood_pressure_reading.dart';

import '../../../../support/test_data.dart';

void main() {
  test('category is normal for healthy values', () {
    final reading = sampleBloodPressureReading(systolic: 118, diastolic: 76);

    expect(reading.category, BloodPressureCategory.normal);
  });

  test('category is elevated for systolic above 120 and low diastolic', () {
    final reading = sampleBloodPressureReading(systolic: 125, diastolic: 79);

    expect(reading.category, BloodPressureCategory.elevated);
  });

  test('category is high stage 1 at boundary values', () {
    final reading = sampleBloodPressureReading(systolic: 130, diastolic: 80);

    expect(reading.category, BloodPressureCategory.highStage1);
  });

  test('category is high stage 2 when pressure is high enough', () {
    final reading = sampleBloodPressureReading(systolic: 145, diastolic: 91);

    expect(reading.category, BloodPressureCategory.highStage2);
  });

  test('category is hypertensive crisis when either threshold is exceeded', () {
    final reading = sampleBloodPressureReading(systolic: 181, diastolic: 100);

    expect(reading.category, BloodPressureCategory.hypertensiveCrisis);
  });

  test('pressureLabel combines systolic and diastolic', () {
    final reading = sampleBloodPressureReading(systolic: 123, diastolic: 77);

    expect(reading.pressureLabel, '123/77');
  });

  test('copyWith overrides selected fields and preserves others', () {
    final reading = sampleBloodPressureReading();

    final updated = reading.copyWith(pulse: 88);

    expect(updated.pulse, 88);
    expect(updated.systolic, reading.systolic);
    expect(updated.id, reading.id);
  });
}
