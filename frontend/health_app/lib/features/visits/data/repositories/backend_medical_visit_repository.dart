import '../../../../core/network/api_exception.dart';
import '../../domain/entities/medical_visit.dart';
import '../../domain/repositories/medical_visit_repository.dart';
import '../datasources/medical_visits_local_data_source.dart';
import '../datasources/medical_visits_remote_data_source.dart';
import '../models/medical_visit_model.dart';

class BackendMedicalVisitRepository implements MedicalVisitRepository {
  BackendMedicalVisitRepository({
    required MedicalVisitsLocalDataSource localDataSource,
    required MedicalVisitsRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final MedicalVisitsLocalDataSource _localDataSource;
  final MedicalVisitsRemoteDataSource _remoteDataSource;

  @override
  Future<List<MedicalVisit>> getCachedVisits() async {
    return _sort(await _localDataSource.getVisits());
  }

  @override
  Future<List<MedicalVisit>> getVisits() async {
    try {
      final remoteVisits = await _remoteDataSource.getVisits();
      final localVisits = await _localDataSource.getVisits();
      final merged = remoteVisits
          .map((visit) => _mergeRemoteWithLocalIdentity(visit, localVisits))
          .toList();

      await _localDataSource.saveAll(
        merged.map(MedicalVisitModel.fromEntity).toList(),
      );
      return _sort(merged);
    } on ApiNetworkException {
      return _sort(await _localDataSource.getVisits());
    }
  }

  @override
  Future<void> saveVisit(MedicalVisit visit) async {
    final savedRemote = visit.remoteId == null || visit.remoteId!.trim().isEmpty
        ? await _remoteDataSource.createVisit(visit)
        : await _remoteDataSource.updateVisit(visit);

    final localVersion = savedRemote.copyWith(id: visit.id);
    final visits = await _localDataSource.getVisits();
    final index = visits.indexWhere((item) => item.id == visit.id);
    if (index == -1) {
      visits.add(MedicalVisitModel.fromEntity(localVersion));
    } else {
      visits[index] = MedicalVisitModel.fromEntity(localVersion);
    }

    await _localDataSource.saveAll(
      _sort(visits).map(MedicalVisitModel.fromEntity).toList(),
    );
  }

  @override
  Future<void> deleteVisit(String id) async {
    final visits = await _localDataSource.getVisits();
    final target = visits
        .where((item) => item.id == id)
        .cast<MedicalVisit?>()
        .firstWhere((item) => item != null, orElse: () => null);

    if (target == null) {
      return;
    }

    final remoteId = target.remoteId?.trim();
    if (remoteId != null && remoteId.isNotEmpty) {
      await _remoteDataSource.deleteVisit(remoteId);
    }

    visits.removeWhere((item) => item.id == id);
    await _localDataSource.saveAll(visits);
  }

  MedicalVisit _mergeRemoteWithLocalIdentity(
    MedicalVisit remoteVisit,
    List<MedicalVisitModel> localVisits,
  ) {
    final existing = localVisits
        .where((item) => item.remoteId == remoteVisit.remoteId)
        .cast<MedicalVisit?>()
        .firstWhere((item) => item != null, orElse: () => null);

    return remoteVisit.copyWith(id: existing?.id ?? remoteVisit.id);
  }

  List<MedicalVisit> _sort(List<MedicalVisit> visits) {
    final sorted = List<MedicalVisit>.from(visits)
      ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return sorted;
  }
}
