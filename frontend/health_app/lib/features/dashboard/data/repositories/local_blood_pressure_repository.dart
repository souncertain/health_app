import '../../domain/entities/blood_pressure_reading.dart';
import '../../domain/repositories/blood_pressure_repository.dart';
import '../../../../core/utils/collection_extensions.dart';
import '../datasources/blood_pressure_local_data_source.dart';
import '../datasources/blood_pressure_remote_data_source.dart';
import '../models/blood_pressure_reading_model.dart';
import '../../../../core/network/api_exception.dart';

class LocalBloodPressureRepository implements BloodPressureRepository {
  LocalBloodPressureRepository(
    this._localDataSource, {
    BloodPressureRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? BloodPressureRemoteDataSource();

  final BloodPressureLocalDataSource _localDataSource;
  final BloodPressureRemoteDataSource _remoteDataSource;
  bool _isSyncing = false;

  @override
  Future<void> deleteReading(String id) async {
    final readings = await _localDataSource.getReadings();
    final target = readings.firstWhereOrNull((reading) => reading.id == id);
    if (target == null) {
      return;
    }

    final updated = List<BloodPressureReadingModel>.from(readings);
    if (target.remoteId == null || target.remoteId!.trim().isEmpty) {
      updated.removeWhere((reading) => reading.id == id);
    } else {
      final index = updated.indexWhere((reading) => reading.id == id);
      updated[index] = BloodPressureReadingModel.fromEntity(
        target.copyWith(
          updatedAt: DateTime.now(),
          syncState: BloodPressureSyncState.pendingDelete,
        ),
      );
    }

    await _localDataSource.saveAll(updated);
    await _synchronizePendingChanges();
  }

  @override
  Future<List<BloodPressureReading>> getReadings() async {
    await _synchronizePendingChanges(suppressErrors: true);

    final readings = await _localDataSource.getReadings();
    final visibleReadings =
        readings
            .where(
              (reading) =>
                  reading.syncState != BloodPressureSyncState.pendingDelete,
            )
            .toList()
          ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));

    return visibleReadings;
  }

  @override
  Future<void> saveReading(BloodPressureReading reading) async {
    final readings = await _localDataSource.getReadings();
    final model = BloodPressureReadingModel.fromEntity(
      reading.copyWith(syncState: BloodPressureSyncState.pendingUpload),
    );
    final index = readings.indexWhere((item) => item.id == reading.id);

    if (index == -1) {
      readings.add(model);
    } else {
      readings[index] = model;
    }

    readings.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    await _localDataSource.saveAll(readings);
    await _synchronizePendingChanges();
  }

  Future<void> _synchronizePendingChanges({bool suppressErrors = false}) async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;
    try {
      var localReadings = await _localDataSource.getReadings();
      localReadings = await _pushPendingDeletions(localReadings);
      localReadings = await _pushPendingUpserts(localReadings);
      final remoteReadings = await _remoteDataSource.getReadings();
      final merged = _mergeRemoteAndPending(
        remoteReadings: remoteReadings,
        localReadings: localReadings,
      );
      await _localDataSource.saveAll(
        merged.map(BloodPressureReadingModel.fromEntity).toList(),
      );
    } on ApiNetworkException {
      if (!suppressErrors) {
        return;
      }
    } catch (_) {
      if (!suppressErrors) {
        return;
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<BloodPressureReadingModel>> _pushPendingDeletions(
    List<BloodPressureReadingModel> localReadings,
  ) async {
    final updated = List<BloodPressureReadingModel>.from(localReadings);
    final pendingDeletes = localReadings
        .where(
          (reading) =>
              reading.syncState == BloodPressureSyncState.pendingDelete &&
              reading.remoteId != null &&
              reading.remoteId!.trim().isNotEmpty,
        )
        .toList();

    for (final reading in pendingDeletes) {
      try {
        await _remoteDataSource.deleteReading(reading.remoteId!);
        updated.removeWhere((item) => item.id == reading.id);
      } on ApiNetworkException {
        rethrow;
      } catch (_) {
        continue;
      }
    }

    return updated;
  }

  Future<List<BloodPressureReadingModel>> _pushPendingUpserts(
    List<BloodPressureReadingModel> localReadings,
  ) async {
    final updated = List<BloodPressureReadingModel>.from(localReadings);
    final pendingUpserts = localReadings
        .where(
          (reading) =>
              reading.syncState == BloodPressureSyncState.localOnly ||
              reading.syncState == BloodPressureSyncState.pendingUpload,
        )
        .toList();

    for (final reading in pendingUpserts) {
      try {
        final syncedReading =
            reading.remoteId == null || reading.remoteId!.trim().isEmpty
            ? await _remoteDataSource.createReading(reading)
            : await _remoteDataSource.updateReading(reading);

        final index = updated.indexWhere((item) => item.id == reading.id);
        if (index != -1) {
          updated[index] = BloodPressureReadingModel.fromEntity(
            syncedReading.copyWith(id: reading.id),
          );
        }
      } on ApiNetworkException {
        rethrow;
      } catch (_) {
        continue;
      }
    }

    return updated;
  }

  List<BloodPressureReading> _mergeRemoteAndPending({
    required List<BloodPressureReading> remoteReadings,
    required List<BloodPressureReadingModel> localReadings,
  }) {
    final pendingByRemoteId = <String, BloodPressureReading>{};
    final pendingWithoutRemoteId = <BloodPressureReading>[];
    final syncedLocalIdByRemoteId = <String, String>{};

    for (final reading in localReadings) {
      final remoteId = reading.remoteId?.trim();
      if (reading.syncState == BloodPressureSyncState.synced &&
          remoteId != null &&
          remoteId.isNotEmpty) {
        syncedLocalIdByRemoteId[remoteId] = reading.id;
        continue;
      }

      if (remoteId == null || remoteId.isEmpty) {
        pendingWithoutRemoteId.add(reading);
        continue;
      }

      pendingByRemoteId[remoteId] = reading;
    }

    final merged = <BloodPressureReading>[
      ...pendingWithoutRemoteId,
      ...pendingByRemoteId.values,
    ];

    for (final remoteReading in remoteReadings) {
      final remoteId = remoteReading.remoteId?.trim();
      if (remoteId == null || remoteId.isEmpty) {
        continue;
      }

      if (pendingByRemoteId.containsKey(remoteId)) {
        continue;
      }

      merged.add(
        remoteReading.copyWith(
          id: syncedLocalIdByRemoteId[remoteId] ?? 'bp-remote-$remoteId',
          syncState: BloodPressureSyncState.synced,
        ),
      );
    }

    merged.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return merged;
  }
}
