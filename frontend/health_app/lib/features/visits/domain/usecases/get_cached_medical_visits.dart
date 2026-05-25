import '../entities/medical_visit.dart';
import '../repositories/medical_visit_repository.dart';

class GetCachedMedicalVisitsUseCase {
  const GetCachedMedicalVisitsUseCase(this._repository);

  final MedicalVisitRepository _repository;

  Future<List<MedicalVisit>> call() {
    return _repository.getCachedVisits();
  }
}
