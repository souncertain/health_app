import '../entities/medical_visit.dart';
import '../repositories/medical_visit_repository.dart';

class SaveMedicalVisitUseCase {
  const SaveMedicalVisitUseCase(this._repository);

  final MedicalVisitRepository _repository;

  Future<void> call(MedicalVisit visit) {
    return _repository.saveVisit(visit);
  }
}
