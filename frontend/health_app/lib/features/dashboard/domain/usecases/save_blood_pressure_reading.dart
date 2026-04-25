import '../entities/blood_pressure_reading.dart';
import '../repositories/blood_pressure_repository.dart';

class SaveBloodPressureReadingUseCase {
  const SaveBloodPressureReadingUseCase(this._repository);

  final BloodPressureRepository _repository;

  Future<void> call(BloodPressureReading reading) {
    return _repository.saveReading(reading);
  }
}
