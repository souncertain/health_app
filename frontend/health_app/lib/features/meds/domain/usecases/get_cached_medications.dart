import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetCachedMedicationsUseCase {
  const GetCachedMedicationsUseCase(this._repository);

  final MedicationRepository _repository;

  Future<List<Medication>> call() {
    return _repository.getCachedMedications();
  }
}
