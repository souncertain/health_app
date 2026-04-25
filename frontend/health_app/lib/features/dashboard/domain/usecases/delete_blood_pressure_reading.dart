import '../repositories/blood_pressure_repository.dart';

class DeleteBloodPressureReadingUseCase {
  const DeleteBloodPressureReadingUseCase(this._repository);

  final BloodPressureRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteReading(id);
  }
}
