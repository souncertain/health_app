import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/health_metric_item.dart';

class HealthMetricsRemoteDataSource {
  HealthMetricsRemoteDataSource({AuthenticatedApiClient? apiClient})
    : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<List<HealthMetricItem>> getMetrics() async {
    final json = await _apiClient.getJson('/api/healthmetric');
    if (json is! List) {
      return const [];
    }

    return json.whereType<Map<String, dynamic>>().map(fromRemoteJson).toList();
  }

  Future<HealthMetricItem> createMetric(HealthMetricItem metric) async {
    final json = await _apiClient.postJson(
      '/api/healthmetric',
      payload: _metricPayload(metric),
    );
    return fromRemoteJson(json as Map<String, dynamic>);
  }

  Future<HealthMetricItem> updateMetric(HealthMetricItem metric) async {
    final remoteId = metric.remoteId;
    if (remoteId == null || remoteId.isEmpty) {
      throw StateError('Cannot update metric without remoteId.');
    }

    final json = await _apiClient.putJson(
      '/api/healthmetric',
      queryParameters: {'id': remoteId},
      payload: _metricPayload(metric),
    );
    return fromRemoteJson(json as Map<String, dynamic>);
  }

  Future<void> deleteMetric(String remoteId) async {
    await _apiClient.deleteJson(
      '/api/healthmetric',
      queryParameters: {'id': remoteId},
    );
  }

  Future<MetricRecord> createRecord({
    required String healthMetricRemoteId,
    required MetricRecord record,
  }) async {
    final json = await _apiClient.postJson(
      '/api/metricrecord',
      payload: _recordPayload(
        healthMetricRemoteId: healthMetricRemoteId,
        record: record,
      ),
    );
    return _recordFromJson(json as Map<String, dynamic>);
  }

  Future<MetricRecord> updateRecord({
    required String recordRemoteId,
    required String healthMetricRemoteId,
    required MetricRecord record,
  }) async {
    final json = await _apiClient.putJson(
      '/api/metricrecord',
      queryParameters: {'id': recordRemoteId},
      payload: _recordPayload(
        healthMetricRemoteId: healthMetricRemoteId,
        record: record,
      ),
    );
    return _recordFromJson(json as Map<String, dynamic>);
  }

  HealthMetricItem fromRemoteJson(Map<String, dynamic> json) {
    final remoteId = json['id'] as String? ?? '';
    return HealthMetricItem(
      id: remoteId,
      title: json['title'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      targetMin: (json['targetMin'] as num?)?.toDouble() ?? 0,
      targetMax: (json['targetMax'] as num?)?.toDouble() ?? 0,
      visualStyle: _visualStyleFromBackend(json['visualStyle']),
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_recordFromJson)
          .toList(),
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['lastUpdatedAt'] as String),
      isCustom: json['isCustom'] as bool? ?? false,
      remoteId: remoteId,
      syncState: MetricSyncState.synced,
    );
  }

  MetricRecord _recordFromJson(Map<String, dynamic> json) {
    return MetricRecord(
      id: json['id'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      recordedOn: _parseDateOnly(json['recordedOn'] as String),
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> _metricPayload(HealthMetricItem metric) {
    return {
      'title': metric.title,
      'unit': metric.unit,
      'targetMin': metric.targetMin,
      'targetMax': metric.targetMax,
      'visualStyle': _visualStyleToBackend(metric.visualStyle),
    };
  }

  Map<String, dynamic> _recordPayload({
    required String healthMetricRemoteId,
    required MetricRecord record,
  }) {
    return {
      'healthMetricId': healthMetricRemoteId,
      'value': record.value,
      'recordedOn': _serializeDateOnly(record.recordedOn),
    };
  }

  DateTime _parseDateOnly(String raw) {
    final parsed = DateTime.parse(raw);
    final normalized = parsed.isUtc ? parsed.toLocal() : parsed;
    return HealthMetricItem.normalizeDate(normalized);
  }

  String _serializeDateOnly(DateTime date) {
    final normalized = HealthMetricItem.normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime _parseTimestamp(String raw) {
    final parsed = DateTime.parse(raw);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  MetricVisualStyle _visualStyleFromBackend(dynamic rawValue) {
    final value = rawValue is num
        ? rawValue.toInt()
        : int.tryParse('$rawValue');
    switch (value) {
      case 2:
        return MetricVisualStyle.redCircle;
      case 3:
        return MetricVisualStyle.violetHeart;
      case 4:
        return MetricVisualStyle.cyanBalance;
      case 5:
        return MetricVisualStyle.emeraldPulse;
      case 6:
        return MetricVisualStyle.coralSun;
      case 1:
      default:
        return MetricVisualStyle.amberDrop;
    }
  }

  int _visualStyleToBackend(MetricVisualStyle style) {
    switch (style) {
      case MetricVisualStyle.amberDrop:
        return 1;
      case MetricVisualStyle.redCircle:
        return 2;
      case MetricVisualStyle.violetHeart:
        return 3;
      case MetricVisualStyle.cyanBalance:
        return 4;
      case MetricVisualStyle.emeraldPulse:
        return 5;
      case MetricVisualStyle.coralSun:
        return 6;
    }
  }
}
