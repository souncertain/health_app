import '../../domain/entities/blood_pressure_reading.dart';
import '../../domain/repositories/blood_pressure_repository.dart';
import '../datasources/blood_pressure_local_data_source.dart';
import '../models/blood_pressure_reading_model.dart';

class LocalBloodPressureRepository implements BloodPressureRepository {
  const LocalBloodPressureRepository(this._localDataSource);

  final BloodPressureLocalDataSource _localDataSource;

  @override
  Future<void> deleteReading(String id) async {
    final readings = await _localDataSource.getReadings();
    final updated = readings.where((reading) => reading.id != id).toList();
    await _localDataSource.saveAll(updated);
  }

  @override
  Future<List<BloodPressureReading>> getReadings() async {
    final readings = await _localDataSource.getReadings();
    return readings
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
  }

  @override
  Future<void> saveReading(BloodPressureReading reading) async {
    final readings = await _localDataSource.getReadings();
    final model = BloodPressureReadingModel.fromEntity(reading);
    final index = readings.indexWhere((item) => item.id == reading.id);

    if (index == -1) {
      readings.add(model);
    } else {
      readings[index] = model;
    }

    readings.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    await _localDataSource.saveAll(readings);
  }
}
