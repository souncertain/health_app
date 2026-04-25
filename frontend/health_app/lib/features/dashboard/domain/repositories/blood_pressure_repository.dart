import '../entities/blood_pressure_reading.dart';

abstract interface class BloodPressureRepository {
  Future<List<BloodPressureReading>> getReadings();

  Future<void> saveReading(BloodPressureReading reading);

  Future<void> deleteReading(String id);
}
