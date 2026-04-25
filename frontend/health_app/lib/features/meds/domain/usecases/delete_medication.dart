import '../repositories/medication_repository.dart';

class DeleteMedicationUseCase {
  const DeleteMedicationUseCase(this._repository);

  final MedicationRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteMedication(id);
  }
}
