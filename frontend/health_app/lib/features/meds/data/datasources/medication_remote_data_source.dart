import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/medication.dart';

class MedicationDailyStatusSnapshot {
  const MedicationDailyStatusSnapshot({
    required this.date,
    required this.status,
  });

  final DateTime date;
  final MedicationDayStatus? status;
}

class MedicationRemoteDataSource {
  MedicationRemoteDataSource({AuthenticatedApiClient? apiClient})
    : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<List<Medication>> getMedications() async {
    final json = await _apiClient.getJson('/api/medications');
    if (json is! List) {
      return const [];
    }

    return json.whereType<Map<String, dynamic>>().map(fromRemoteJson).toList();
  }

  Future<Medication> createMedication(Medication medication) async {
    final json = await _apiClient.postJson(
      '/api/medications',
      payload: _toPayload(medication),
    );
    return fromRemoteJson(json as Map<String, dynamic>);
  }

  Future<Medication> updateMedication(Medication medication) async {
    final remoteId = medication.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      throw StateError('Cannot update medication without remoteId.');
    }

    final json = await _apiClient.putJson(
      '/api/medications',
      queryParameters: {'id': remoteId},
      payload: _toPayload(medication),
    );
    return fromRemoteJson(json as Map<String, dynamic>);
  }

  Future<void> deleteMedication(String remoteId) async {
    await _apiClient.deleteJson(
      '/api/medications',
      queryParameters: {'id': remoteId},
    );
  }

  Medication fromRemoteJson(Map<String, dynamic> json) {
    final remoteId = json['id'] as String? ?? '';
    final scheduledWeekdays =
        (json['scheduledWeekdays'] as List<dynamic>? ?? const [])
            .map((item) => (item as num).toInt())
            .toList();
    final rawDailyStatuses =
        (json['dailyStatuses'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>();

    return Medication(
      id: remoteId,
      name: json['name'] as String? ?? '',
      dosage: _formatDosage(
        dosageValue: (json['dosageValue'] as num?)?.toDouble() ?? 0,
        dosageUnit: json['dosageUnit'] as String? ?? '',
      ),
      frequency: _frequencyFromBackend(json['frequency']),
      timesInMinutes: (json['timesInMinutes'] as List<dynamic>? ?? const [])
          .map((item) => (item as num).toInt())
          .toList(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      form: _resolveForm(json['name'] as String? ?? ''),
      scheduledWeekdays: scheduledWeekdays,
      dayStatuses: {
        for (final item in rawDailyStatuses)
          Medication.dateKey(_parseDateOnly(item['date'] as String)):
              _dailyStatusFromBackend(item['status']),
      },
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['lastUpdatedAt'] as String),
      remoteId: remoteId,
      syncState: MedicationSyncState.synced,
    );
  }

  Future<MedicationDailyStatusSnapshot?> setDailyStatus({
    required String medicationRemoteId,
    required DateTime date,
    required MedicationDayStatus? status,
  }) async {
    final json = await _apiClient.putJson(
      '/api/medications/$medicationRemoteId/daily-status',
      payload: {
        'date': _serializeDateOnly(date),
        'status': status == null ? null : _dailyStatusToBackend(status),
      },
    );

    if (json == null) {
      return null;
    }

    final map = json as Map<String, dynamic>;
    return MedicationDailyStatusSnapshot(
      date: _parseDateOnly(map['date'] as String),
      status: _dailyStatusFromBackend(map['status']),
    );
  }

  Map<String, dynamic> _toPayload(Medication medication) {
    final parsedDosage = _parseDosage(medication.dosage);
    return {
      'name': medication.name,
      'dosageValue': parsedDosage.value,
      'dosageUnit': parsedDosage.unit,
      'frequency': _frequencyToBackend(medication.frequency),
      'timesInMinutes': medication.timesInMinutes,
      'notificationsEnabled': medication.notificationsEnabled,
      'scheduledWeekdays': medication.scheduledWeekdays,
    };
  }

  MedicationFrequency _frequencyFromBackend(dynamic rawValue) {
    final value = rawValue is num
        ? rawValue.toInt()
        : int.tryParse('$rawValue');
    switch (value) {
      case 2:
        return MedicationFrequency.twiceDaily;
      case 3:
        return MedicationFrequency.threeTimesDaily;
      case 4:
        return MedicationFrequency.dayAfterDay;
      case 5:
        return MedicationFrequency.weekly;
      case 1:
      default:
        return MedicationFrequency.onceDaily;
    }
  }

  int _frequencyToBackend(MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.onceDaily:
        return 1;
      case MedicationFrequency.twiceDaily:
        return 2;
      case MedicationFrequency.threeTimesDaily:
        return 3;
      case MedicationFrequency.dayAfterDay:
        return 4;
      case MedicationFrequency.weekly:
        return 5;
    }
  }

  DateTime _parseTimestamp(String raw) {
    final parsed = DateTime.parse(raw);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  DateTime _parseDateOnly(String raw) {
    final parsed = DateTime.parse(raw);
    final normalized = parsed.isUtc ? parsed.toLocal() : parsed;
    return DateTime(normalized.year, normalized.month, normalized.day);
  }

  String _serializeDateOnly(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  MedicationDayStatus _dailyStatusFromBackend(dynamic rawValue) {
    final value = rawValue is num
        ? rawValue.toInt()
        : int.tryParse('$rawValue');
    switch (value) {
      case 2:
        return MedicationDayStatus.pending;
      case 3:
        return MedicationDayStatus.missed;
      case 1:
        return MedicationDayStatus.taken;
      default:
        return MedicationDayStatus.pending;
    }
  }

  int _dailyStatusToBackend(MedicationDayStatus status) {
    switch (status) {
      case MedicationDayStatus.taken:
        return 1;
      case MedicationDayStatus.pending:
        return 2;
      case MedicationDayStatus.missed:
        return 3;
    }
  }

  MedicationForm _resolveForm(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('met') || normalized.contains('мет')) {
      return MedicationForm.syringe;
    }
    if (normalized.contains('statin') || normalized.contains('статин')) {
      return MedicationForm.circle;
    }
    if (normalized.contains('pril') || normalized.contains('прил')) {
      return MedicationForm.capsule;
    }
    return MedicationForm.tablet;
  }

  String _formatDosage({
    required double dosageValue,
    required String dosageUnit,
  }) {
    final valueText = dosageValue.truncateToDouble() == dosageValue
        ? dosageValue.toStringAsFixed(0)
        : dosageValue.toStringAsFixed(1);
    return dosageUnit.trim().isEmpty
        ? valueText
        : '$valueText ${dosageUnit.trim()}';
  }

  _ParsedDosage _parseDosage(String dosage) {
    final trimmed = dosage.trim();
    final match = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(.*)$').firstMatch(trimmed);
    if (match == null) {
      return _ParsedDosage(value: 1, unit: trimmed);
    }

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 1;
    final unit = match.group(2)?.trim() ?? '';
    return _ParsedDosage(value: value, unit: unit);
  }
}

class _ParsedDosage {
  const _ParsedDosage({required this.value, required this.unit});

  final double value;
  final String unit;
}
