import '../entities/medical_visit.dart';

abstract interface class MedicalVisitRepository {
  Future<List<MedicalVisit>> getVisits();

  Future<void> saveVisit(MedicalVisit visit);

  Future<void> deleteVisit(String id);
}
