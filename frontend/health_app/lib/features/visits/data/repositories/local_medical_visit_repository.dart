import '../../domain/entities/medical_visit.dart';
import '../../domain/repositories/medical_visit_repository.dart';
import '../datasources/medical_visits_local_data_source.dart';
import '../models/medical_visit_model.dart';

class LocalMedicalVisitRepository implements MedicalVisitRepository {
  const LocalMedicalVisitRepository(this._localDataSource);

  final MedicalVisitsLocalDataSource _localDataSource;

  @override
  Future<List<MedicalVisit>> getCachedVisits() {
    return getVisits();
  }

  @override
  Future<List<MedicalVisit>> getVisits() async {
    final visits = await _localDataSource.getVisits();
    visits.sort(_sortVisits);
    return visits;
  }

  @override
  Future<void> saveVisit(MedicalVisit visit) async {
    final visits = await _localDataSource.getVisits();
    final model = MedicalVisitModel.fromEntity(visit);
    final index = visits.indexWhere((item) => item.id == visit.id);

    if (index == -1) {
      visits.add(model);
    } else {
      visits[index] = model;
    }

    visits.sort(_sortVisits);
    await _localDataSource.saveAll(visits);
  }

  @override
  Future<void> deleteVisit(String id) async {
    final visits = await _localDataSource.getVisits();
    visits.removeWhere((item) => item.id == id);
    visits.sort(_sortVisits);
    await _localDataSource.saveAll(visits);
  }

  int _sortVisits(MedicalVisit left, MedicalVisit right) {
    return left.scheduledAt.compareTo(right.scheduledAt);
  }
}
