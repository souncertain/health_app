import '../repositories/medical_visit_repository.dart';

class DeleteMedicalVisitUseCase {
  const DeleteMedicalVisitUseCase(this._repository);

  final MedicalVisitRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteVisit(id);
  }
}
