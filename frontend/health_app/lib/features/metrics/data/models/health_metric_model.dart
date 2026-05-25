import '../../domain/entities/health_metric_item.dart';

class MetricRecordModel extends MetricRecord {
  const MetricRecordModel({
    required super.id,
    required super.value,
    required super.recordedOn,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MetricRecordModel.fromEntity(MetricRecord record) {
    return MetricRecordModel(
      id: record.id,
      value: record.value,
      recordedOn: record.recordedOn,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  factory MetricRecordModel.fromJson(Map<String, dynamic> json) {
    final parsedRecordedOn = DateTime.parse(json['recordedOn'] as String);
    final normalizedRecordedOn = parsedRecordedOn.isUtc
        ? parsedRecordedOn.toLocal()
        : parsedRecordedOn;
    return MetricRecordModel(
      id: json['id'] as String,
      value: (json['value'] as num).toDouble(),
      recordedOn: HealthMetricItem.normalizeDate(normalizedRecordedOn),
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'recordedOn': recordedOn.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class HealthMetricModel extends HealthMetricItem {
  const HealthMetricModel({
    required super.id,
    required super.title,
    required super.unit,
    required super.targetMin,
    required super.targetMax,
    required super.visualStyle,
    required super.records,
    required super.createdAt,
    required super.updatedAt,
    required super.isCustom,
    super.remoteId,
    super.syncState,
  });

  factory HealthMetricModel.fromEntity(HealthMetricItem metric) {
    return HealthMetricModel(
      id: metric.id,
      title: metric.title,
      unit: metric.unit,
      targetMin: metric.targetMin,
      targetMax: metric.targetMax,
      visualStyle: metric.visualStyle,
      records: metric.records,
      createdAt: metric.createdAt,
      updatedAt: metric.updatedAt,
      isCustom: metric.isCustom,
      remoteId: metric.remoteId,
      syncState: metric.syncState,
    );
  }

  factory HealthMetricModel.fromJson(Map<String, dynamic> json) {
    return HealthMetricModel(
      id: json['id'] as String,
      title: json['title'] as String,
      unit: json['unit'] as String,
      targetMin: (json['targetMin'] as num).toDouble(),
      targetMax: (json['targetMax'] as num).toDouble(),
      visualStyle: MetricVisualStyle.values.firstWhere(
        (style) => style.name == json['visualStyle'],
      ),
      records: (json['records'] as List<dynamic>)
          .map(
            (item) => MetricRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['updatedAt'] as String),
      isCustom: json['isCustom'] as bool? ?? false,
      remoteId: json['remoteId'] as String?,
      syncState: MetricSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => MetricSyncState.localOnly,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'unit': unit,
      'targetMin': targetMin,
      'targetMax': targetMax,
      'visualStyle': visualStyle.name,
      'records': records
          .map((record) => MetricRecordModel.fromEntity(record).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCustom': isCustom,
      'remoteId': remoteId,
      'syncState': syncState.name,
    };
  }
}

DateTime _parseTimestamp(String raw) {
  final parsed = DateTime.parse(raw);
  return parsed.isUtc ? parsed.toLocal() : parsed;
}
