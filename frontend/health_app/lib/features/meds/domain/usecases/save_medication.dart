import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class SaveMedicationUseCase {
  const SaveMedicationUseCase(this._repository);

  final MedicationRepository _repository;

  Future<void> call(Medication medication) {
    return _repository.saveMedication(medication);
  }
}
