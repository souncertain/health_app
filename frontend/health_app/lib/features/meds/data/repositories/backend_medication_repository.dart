import '../../../../core/network/api_exception.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_data_source.dart';
import '../datasources/medication_remote_data_source.dart';
import '../models/medication_model.dart';

class BackendMedicationRepository implements MedicationRepository {
  BackendMedicationRepository({
    required MedicationLocalDataSource localDataSource,
    required MedicationRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final MedicationLocalDataSource _localDataSource;
  final MedicationRemoteDataSource _remoteDataSource;

  @override
  Future<List<Medication>> getCachedMedications() async {
    return _sort(await _localDataSource.getMedications());
  }

  @override
  Future<List<Medication>> getMedications() async {
    try {
      final localMedications = await _localDataSource.getMedications();
      final remoteMedications = await _remoteDataSource.getMedications();
      final syncedRemoteMedications = await _syncDailyStatuses(
        remoteMedications,
        localMedications,
      );
      final merged = syncedRemoteMedications
          .map(
            (medication) =>
                _mergeRemoteWithLocalState(
                  medication,
                  localMedications,
                ),
          )
          .toList();

      await _localDataSource.saveAll(
        merged.map(MedicationModel.fromEntity).toList(),
      );
      return _sort(merged);
    } on ApiNetworkException {
      return _sort(await _localDataSource.getMedications());
    }
  }

  @override
  Future<void> saveMedication(Medication medication) async {
    final savedRemote =
        medication.remoteId == null || medication.remoteId!.trim().isEmpty
        ? await _remoteDataSource.createMedication(medication)
        : await _remoteDataSource.updateMedication(medication);

    final localVersion = _mergeRemoteWithDraft(savedRemote, medication);
    final medications = await _localDataSource.getMedications();
    final index = medications.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      medications.add(MedicationModel.fromEntity(localVersion));
    } else {
      medications[index] = MedicationModel.fromEntity(localVersion);
    }

    await _localDataSource.saveAll(
      _sort(medications).map(MedicationModel.fromEntity).toList(),
    );
  }

  @override
  Future<void> deleteMedication(String id) async {
    final medications = await _localDataSource.getMedications();
    final target = medications
        .where((item) => item.id == id)
        .cast<Medication?>()
        .firstWhere((item) => item != null, orElse: () => null);

    if (target == null) {
      return;
    }

    final remoteId = target.remoteId?.trim();
    if (remoteId != null && remoteId.isNotEmpty) {
      await _remoteDataSource.deleteMedication(remoteId);
    }

    medications.removeWhere((item) => item.id == id);
    await _localDataSource.saveAll(medications);
  }

  @override
  Future<void> setMedicationDailyStatus(
    String medicationId,
    DateTime date,
    MedicationDayStatus? status,
  ) async {
    final medications = await _localDataSource.getMedications();
    final index = medications.indexWhere((item) => item.id == medicationId);
    if (index == -1) {
      return;
    }

    final target = medications[index];
    final remoteId = target.remoteId?.trim();
    final updatedLocal = target.copyWithStatusForDate(date, status);

    if (remoteId == null || remoteId.isEmpty) {
      medications[index] = MedicationModel.fromEntity(updatedLocal);
      await _localDataSource.saveAll(medications);
      return;
    }

    try {
      final snapshot = await _remoteDataSource.setDailyStatus(
        medicationRemoteId: remoteId,
        date: date,
        status: status,
      );
      final syncedMedication = updatedLocal.copyWithStatusForDate(
        date,
        snapshot?.status ?? status,
      );
      medications[index] = MedicationModel.fromEntity(syncedMedication);
      await _localDataSource.saveAll(medications);
    } on ApiNetworkException {
      final offlineStatus = status ?? MedicationDayStatus.pending;
      medications[index] = MedicationModel.fromEntity(
        target.copyWithStatusForDate(date, offlineStatus),
      );
      await _localDataSource.saveAll(medications);
    }
  }

  Medication _mergeRemoteWithLocalState(
    Medication remoteMedication,
    List<MedicationModel> localMedications,
  ) {
    final existing = localMedications
        .where((item) => item.remoteId == remoteMedication.remoteId)
        .cast<Medication?>()
        .firstWhere((item) => item != null, orElse: () => null);

    return remoteMedication.copyWith(
      id: existing?.id ?? remoteMedication.id,
      form: existing?.form ?? remoteMedication.form,
      dayStatuses: remoteMedication.dayStatuses,
    );
  }

  Medication _mergeRemoteWithDraft(
    Medication remoteMedication,
    Medication draftMedication,
  ) {
    return remoteMedication.copyWith(
      id: draftMedication.id,
      form: draftMedication.form,
      dayStatuses: draftMedication.dayStatuses,
    );
  }

  List<Medication> _sort(List<Medication> medications) {
    final sorted = List<Medication>.from(medications)
      ..sort(
        (left, right) =>
            left.timesInMinutes.first.compareTo(right.timesInMinutes.first),
      );
    return sorted;
  }

  Future<List<Medication>> _syncDailyStatuses(
    List<Medication> remoteMedications,
    List<MedicationModel> localMedications,
  ) async {
    final synced = remoteMedications
        .map(
          (item) => item.copyWith(
            dayStatuses: Map<String, MedicationDayStatus>.from(item.dayStatuses),
          ),
        )
        .toList();

    for (final localMedication in localMedications) {
      final remoteId = localMedication.remoteId?.trim();
      if (remoteId == null ||
          remoteId.isEmpty ||
          localMedication.dayStatuses.isEmpty) {
        continue;
      }

      final remoteIndex = synced.indexWhere((item) => item.remoteId == remoteId);
      if (remoteIndex == -1) {
        continue;
      }

      var currentRemoteMedication = synced[remoteIndex];
      for (final entry in localMedication.dayStatuses.entries) {
        final date = _tryDateFromKey(entry.key);
        if (date == null) {
          continue;
        }
        final remoteStatus = currentRemoteMedication.explicitStatusForDate(date);
        final desiredStatus = entry.value == MedicationDayStatus.pending
            ? null
            : entry.value;
        if (remoteStatus == desiredStatus) {
          currentRemoteMedication = currentRemoteMedication.copyWithStatusForDate(
            date,
            desiredStatus,
          );
          continue;
        }

        try {
          final snapshot = await _remoteDataSource.setDailyStatus(
            medicationRemoteId: remoteId,
            date: date,
            status: desiredStatus,
          );
          currentRemoteMedication = currentRemoteMedication.copyWithStatusForDate(
            date,
            snapshot?.status,
          );
        } on ApiNetworkException {
          currentRemoteMedication = currentRemoteMedication.copyWithStatusForDate(
            date,
            desiredStatus ?? MedicationDayStatus.pending,
          );
          break;
        }
      }

      synced[remoteIndex] = currentRemoteMedication;
    }

    return synced;
  }

  DateTime? _tryDateFromKey(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
      return null;
    }

    try {
      final parsed = DateTime.parse(key);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } on FormatException {
      return null;
    }
  }
}
