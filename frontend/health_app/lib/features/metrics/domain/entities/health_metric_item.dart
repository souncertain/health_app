enum MetricSeverity { normal, monitor, critical, noData }

enum MetricTrend { down, stable, up, none }

enum MetricVisualStyle {
  amberDrop,
  redCircle,
  violetHeart,
  cyanBalance,
  emeraldPulse,
  coralSun,
}

enum MetricSyncState { localOnly, pendingUpload, synced }

class MetricRecord {
  const MetricRecord({
    required this.id,
    required this.value,
    required this.recordedOn,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final double value;
  final DateTime recordedOn;
  final DateTime createdAt;
  final DateTime updatedAt;

  MetricRecord copyWith({
    String? id,
    double? value,
    DateTime? recordedOn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MetricRecord(
      id: id ?? this.id,
      value: value ?? this.value,
      recordedOn: recordedOn ?? this.recordedOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HealthMetricItem {
  const HealthMetricItem({
    required this.id,
    required this.title,
    required this.unit,
    required this.targetMin,
    required this.targetMax,
    required this.visualStyle,
    required this.records,
    required this.createdAt,
    required this.updatedAt,
    this.isCustom = false,
    this.remoteId,
    this.syncState = MetricSyncState.localOnly,
  });

  final String id;
  final String title;
  final String unit;
  final double targetMin;
  final double targetMax;
  final MetricVisualStyle visualStyle;
  final List<MetricRecord> records;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCustom;
  final String? remoteId;
  final MetricSyncState syncState;

  HealthMetricItem copyWith({
    String? id,
    String? title,
    String? unit,
    double? targetMin,
    double? targetMax,
    MetricVisualStyle? visualStyle,
    List<MetricRecord>? records,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCustom,
    String? remoteId,
    MetricSyncState? syncState,
  }) {
    return HealthMetricItem(
      id: id ?? this.id,
      title: title ?? this.title,
      unit: unit ?? this.unit,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      visualStyle: visualStyle ?? this.visualStyle,
      records: records ?? this.records,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCustom: isCustom ?? this.isCustom,
      remoteId: remoteId ?? this.remoteId,
      syncState: syncState ?? this.syncState,
    );
  }

  List<MetricRecord> get recordsSortedAscending {
    final sorted = List<MetricRecord>.from(records)
      ..sort((left, right) => left.recordedOn.compareTo(right.recordedOn));
    return sorted;
  }

  List<MetricRecord> get recordsSortedDescending {
    final sorted = List<MetricRecord>.from(records)
      ..sort((left, right) => right.recordedOn.compareTo(left.recordedOn));
    return sorted;
  }

  MetricRecord? get latestRecord =>
      recordsSortedDescending.isEmpty ? null : recordsSortedDescending.first;

  MetricRecord? recordForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    for (final record in records) {
      if (_normalizeDate(record.recordedOn) == normalized) {
        return record;
      }
    }
    return null;
  }

  static DateTime normalizeDate(DateTime date) => _normalizeDate(date);

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
