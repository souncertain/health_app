import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/medical_visit.dart';

class MedicalVisitsRemoteDataSource {
  MedicalVisitsRemoteDataSource({AuthenticatedApiClient? apiClient})
    : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<List<MedicalVisit>> getVisits() async {
    final json = await _apiClient.getJson('/api/visits');
    if (json is! List) {
      return const [];
    }

    return json.whereType<Map<String, dynamic>>().map(fromRemoteJson).toList();
  }

  Future<MedicalVisit> createVisit(MedicalVisit visit) async {
    final json = await _apiClient.postJson(
      '/api/visits',
      payload: _payload(visit),
    );
    return fromRemoteJson(json as Map<String, dynamic>);
  }

  Future<MedicalVisit> updateVisit(MedicalVisit visit) async {
    final remoteId = visit.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      throw StateError('Cannot update visit without remoteId.');
    }

    final json = await _apiClient.putJson(
      '/api/visits',
      queryParameters: {'id': remoteId},
      payload: _payload(visit),
    );
    return fromRemoteJson(json as Map<String, dynamic>);
  }

  Future<void> deleteVisit(String remoteId) async {
    await _apiClient.deleteJson(
      '/api/visits',
      queryParameters: {'id': remoteId},
    );
  }

  MedicalVisit fromRemoteJson(Map<String, dynamic> json) {
    final remoteId = json['id'] as String? ?? '';
    final visitType = _visitTypeFromBackend(json['visitType']);
    return MedicalVisit(
      id: remoteId,
      doctorName: json['doctorName'] as String? ?? '',
      specialty:
          json['speciality'] as String? ?? json['specialty'] as String? ?? '',
      appointmentDate: _parseDateOnly(json['appointmentDate'] as String),
      timeInMinutes: (json['timeInMinutes'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? '',
      visitType: visitType,
      rating: visitType == MedicalVisitType.oneTime ? 4.9 : 4.8,
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['lastUpdatedAt'] as String),
      remoteId: remoteId,
      syncState: MedicalVisitSyncState.synced,
    );
  }

  Map<String, dynamic> _payload(MedicalVisit visit) {
    return {
      'doctorName': visit.doctorName,
      'speciality': visit.specialty,
      'appointmentDate': _serializeDateOnly(visit.appointmentDate),
      'timeInMinutes': visit.timeInMinutes,
      'location': visit.location,
      'visitType': _visitTypeToBackend(visit.visitType),
    };
  }

  DateTime _parseDateOnly(String raw) {
    final parsed = DateTime.parse(raw);
    final normalized = parsed.isUtc ? parsed.toLocal() : parsed;
    return MedicalVisit.normalizeDate(normalized);
  }

  String _serializeDateOnly(DateTime date) {
    final normalized = MedicalVisit.normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime _parseTimestamp(String raw) {
    final parsed = DateTime.parse(raw);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  MedicalVisitType _visitTypeFromBackend(dynamic rawValue) {
    final value = rawValue is num
        ? rawValue.toInt()
        : int.tryParse('$rawValue');
    switch (value) {
      case 2:
        return MedicalVisitType.recurring;
      case 1:
      default:
        return MedicalVisitType.oneTime;
    }
  }

  int _visitTypeToBackend(MedicalVisitType type) {
    switch (type) {
      case MedicalVisitType.oneTime:
        return 1;
      case MedicalVisitType.recurring:
        return 2;
    }
  }
}
