import 'dart:math' as math;

import '../../../../core/controllers/cache_first_collection_controller.dart';
import '../../../../core/utils/collection_extensions.dart';
import '../../domain/entities/health_metric_item.dart';
import '../../domain/usecases/delete_health_metric.dart';
import '../../domain/usecases/get_cached_health_metrics.dart';
import '../../domain/usecases/get_health_metrics.dart';
import '../../domain/usecases/save_health_metric.dart';

class MetricHistoryDay {
  const MetricHistoryDay({required this.date, required this.value});

  final DateTime date;
  final double? value;
}

class MetricsController extends CacheFirstCollectionController<HealthMetricItem> {
  MetricsController({
    required GetCachedHealthMetricsUseCase getCachedMetrics,
    required GetHealthMetricsUseCase getMetrics,
    required SaveHealthMetricUseCase saveMetric,
    required DeleteHealthMetricUseCase deleteMetric,
  }) : _getCachedMetrics = getCachedMetrics,
       _getMetrics = getMetrics,
       _saveMetric = saveMetric,
       _deleteMetric = deleteMetric;

  final GetCachedHealthMetricsUseCase _getCachedMetrics;
  final GetHealthMetricsUseCase _getMetrics;
  final SaveHealthMetricUseCase _saveMetric;
  final DeleteHealthMetricUseCase _deleteMetric;

  static const _customMetricStyles = [
    MetricVisualStyle.emeraldPulse,
    MetricVisualStyle.coralSun,
    MetricVisualStyle.amberDrop,
    MetricVisualStyle.violetHeart,
    MetricVisualStyle.cyanBalance,
    MetricVisualStyle.redCircle,
  ];

  List<HealthMetricItem> get metrics => List.unmodifiable(currentItems);

  @override
  String get refreshErrorMessage =>
      'РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РіСЂСѓР·РёС‚СЊ РјРµС‚СЂРёРєРё.';

  @override
  Future<List<HealthMetricItem>> loadCachedItems() => _getCachedMetrics();

  @override
  Future<List<HealthMetricItem>> loadRemoteItems() => _getMetrics();

  @override
  List<HealthMetricItem> sortItems(List<HealthMetricItem> items) {
    final sorted = List<HealthMetricItem>.from(items);
    _sortInPlace(sorted);
    return sorted;
  }

  Future<String> createCustomMetric({
    required String title,
    required String unit,
    required double targetMin,
    required double targetMax,
  }) async {
    final now = DateTime.now();
    final customCount = currentItems.where((metric) => metric.isCustom).length;
    final metric = HealthMetricItem(
      id: 'metric-${now.microsecondsSinceEpoch}',
      title: title,
      unit: unit,
      targetMin: targetMin,
      targetMax: targetMax,
      visualStyle:
          _customMetricStyles[customCount % _customMetricStyles.length],
      records: const [],
      createdAt: now,
      updatedAt: now,
      isCustom: true,
    );

    await runOptimisticMutation(
      nextItems: _upsertMetric(currentItems, metric),
      action: () => _saveMetric(metric),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕР·РґР°С‚СЊ РјРµС‚СЂРёРєСѓ.',
    );
    return metric.id;
  }

  Future<void> updateMetricDetails({
    required HealthMetricItem metric,
    required String title,
    required String unit,
    required double targetMin,
    required double targetMax,
  }) async {
    final now = DateTime.now();
    final updatedMetric = metric.copyWith(
      title: title,
      unit: unit,
      targetMin: targetMin,
      targetMax: targetMax,
      updatedAt: now,
    );

    await runOptimisticMutation(
      nextItems: _upsertMetric(currentItems, updatedMetric),
      action: () => _saveMetric(updatedMetric),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ РјРµС‚СЂРёРєСѓ.',
      rethrowOnFailure: true,
    );
  }

  Future<void> logMetricValue({
    required HealthMetricItem metric,
    required double value,
    required DateTime recordedOn,
  }) async {
    final normalizedDate = HealthMetricItem.normalizeDate(recordedOn);
    final existingRecord = metric.recordForDate(normalizedDate);
    final now = DateTime.now();
    final updatedRecords = List<MetricRecord>.from(metric.records);

    if (existingRecord == null) {
      updatedRecords.add(
        MetricRecord(
          id: '${metric.id}-rec-${normalizedDate.microsecondsSinceEpoch}',
          value: value,
          recordedOn: normalizedDate,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      final index = updatedRecords.indexWhere(
        (item) => item.id == existingRecord.id,
      );
      updatedRecords[index] = existingRecord.copyWith(
        value: value,
        recordedOn: normalizedDate,
        updatedAt: now,
      );
    }

    final updatedMetric = metric.copyWith(records: updatedRecords, updatedAt: now);
    await runOptimisticMutation(
      nextItems: _upsertMetric(currentItems, updatedMetric),
      action: () => _saveMetric(updatedMetric),
      errorMessage:
          'РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕС…СЂР°РЅРёС‚СЊ Р·РЅР°С‡РµРЅРёРµ РјРµС‚СЂРёРєРё.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteMetric(HealthMetricItem metric) async {
    await runOptimisticMutation(
      nextItems: currentItems.where((item) => item.id != metric.id).toList(),
      action: () => _deleteMetric(metric.id),
      errorMessage: 'РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ РјРµС‚СЂРёРєСѓ.',
      rethrowOnFailure: true,
    );
  }

  int countBySeverity(MetricSeverity severity) {
    return currentItems
        .where((metric) => severityForMetric(metric) == severity)
        .length;
  }

  double? latestValueForMetric(HealthMetricItem metric) {
    return metric.latestRecord?.value;
  }

  MetricSeverity severityForMetric(HealthMetricItem metric) {
    final latestValue = latestValueForMetric(metric);
    if (latestValue == null) {
      return MetricSeverity.noData;
    }

    if (latestValue >= metric.targetMin && latestValue <= metric.targetMax) {
      return MetricSeverity.normal;
    }

    final targetRange = math.max(metric.targetMax - metric.targetMin, 1);
    final lowerMonitorBound = metric.targetMin - (targetRange * 0.2);
    final upperMonitorBound = metric.targetMax + (targetRange * 0.2);

    if (latestValue >= lowerMonitorBound && latestValue <= upperMonitorBound) {
      return MetricSeverity.monitor;
    }

    return MetricSeverity.critical;
  }

  MetricTrend trendForMetric(HealthMetricItem metric) {
    final records = metric.recordsSortedAscending;
    if (records.length < 2) {
      return MetricTrend.none;
    }

    final last = records[records.length - 1].value;
    final previous = records[records.length - 2].value;
    final delta = last - previous;
    if (delta.abs() < 0.01) {
      return MetricTrend.stable;
    }
    return delta.isNegative ? MetricTrend.down : MetricTrend.up;
  }

  double progressForMetric(HealthMetricItem metric) {
    final latestValue = latestValueForMetric(metric);
    if (latestValue == null) {
      return 0;
    }

    final range = math.max(metric.targetMax - metric.targetMin, 1);
    final progress = (latestValue - metric.targetMin) / range;
    return progress.clamp(0.0, 1.0);
  }

  List<double> sparklineValuesForMetric(HealthMetricItem metric) {
    final history = historyForMetric(metric);
    final values = history
        .where((item) => item.value != null)
        .map((item) => item.value!)
        .toList();

    if (values.length < 2) {
      return const [];
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.001);

    return history
        .where((item) => item.value != null)
        .map((item) => (item.value! - minValue) / range)
        .toList();
  }

  List<MetricHistoryDay> historyForMetric(HealthMetricItem metric) {
    final today = HealthMetricItem.normalizeDate(DateTime.now());
    return List<MetricHistoryDay>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final record = metric.recordForDate(date);
      return MetricHistoryDay(date: date, value: record?.value);
    });
  }

  bool hasRenderableHistory(HealthMetricItem metric) {
    return historyForMetric(
          metric,
        ).where((item) => item.value != null).length >=
        2;
  }

  List<HealthMetricItem> _upsertMetric(
    List<HealthMetricItem> source,
    HealthMetricItem metric,
  ) {
    final updated = List<HealthMetricItem>.from(source);
    updated.upsertWhere(metric, (item) => item.id == metric.id);
    _sortInPlace(updated);
    return updated;
  }

  void _sortInPlace(List<HealthMetricItem> metrics) {
    metrics.sort((left, right) {
      final updatedAtComparison = right.updatedAt.compareTo(left.updatedAt);
      if (updatedAtComparison != 0) {
        return updatedAtComparison;
      }

      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });
  }
}
