import '../entities/blood_pressure_reading.dart';
import '../repositories/blood_pressure_repository.dart';

class GetBloodPressureReadingsUseCase {
  const GetBloodPressureReadingsUseCase(this._repository);

  final BloodPressureRepository _repository;

  Future<List<BloodPressureReading>> call() {
    return _repository.getReadings();
  }
}
