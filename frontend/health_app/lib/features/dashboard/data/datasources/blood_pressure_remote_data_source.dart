import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/blood_pressure_reading.dart';

class BloodPressureRemoteDataSource {
  BloodPressureRemoteDataSource({AuthenticatedApiClient? apiClient})
    : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<List<BloodPressureReading>> getReadings() async {
    final json = await _apiClient.getJson('/api/pressures');
    if (json is! List) {
      return const [];
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => fromRemoteJson(item, localId: item['id'] as String? ?? ''),
        )
        .toList();
  }

  Future<BloodPressureReading> createReading(
    BloodPressureReading reading,
  ) async {
    final json = await _apiClient.postJson(
      '/api/pressures',
      payload: _toUpsertPayload(reading),
    );

    return fromRemoteJson(json as Map<String, dynamic>, localId: reading.id);
  }

  Future<BloodPressureReading> updateReading(
    BloodPressureReading reading,
  ) async {
    final remoteId = reading.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      throw StateError('Cannot update a reading without remoteId.');
    }

    final json = await _apiClient.putJson(
      '/api/pressures',
      queryParameters: {'id': remoteId},
      payload: _toUpsertPayload(reading),
    );

    return fromRemoteJson(json as Map<String, dynamic>, localId: reading.id);
  }

  Future<void> deleteReading(String remoteId) async {
    await _apiClient.deleteJson(
      '/api/pressures',
      queryParameters: {'id': remoteId},
    );
  }

  BloodPressureReading fromRemoteJson(
    Map<String, dynamic> json, {
    required String localId,
  }) {
    final remoteId = json['id'] as String? ?? '';

    return BloodPressureReading(
      id: localId.isEmpty ? 'bp-remote-$remoteId' : localId,
      systolic: (json['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (json['diastolic'] as num?)?.toInt() ?? 0,
      pulse: (json['pulse'] as num?)?.toInt() ?? 0,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      remoteId: remoteId,
      syncState: BloodPressureSyncState.synced,
    );
  }

  Map<String, dynamic> _toUpsertPayload(BloodPressureReading reading) {
    return {
      'systolic': reading.systolic,
      'diastolic': reading.diastolic,
      'pulse': reading.pulse,
      'recordedAt': reading.recordedAt.toUtc().toIso8601String(),
      'source': 'HandNote',
    };
  }
}
