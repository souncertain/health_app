import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

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

class MetricsController extends ChangeNotifier {
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

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<HealthMetricItem> _metrics = const [];
  bool _initialized = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<HealthMetricItem> get metrics => List.unmodifiable(_metrics);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await _loadCached();
    unawaited(refresh(showLoading: _metrics.isEmpty));
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      _setMetrics(await _getMetrics());
    } catch (_) {
      _errorMessage = 'Не удалось загрузить метрики.';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<String> createCustomMetric({
    required String title,
    required String unit,
    required double targetMin,
    required double targetMax,
  }) async {
    final now = DateTime.now();
    final customCount = _metrics.where((metric) => metric.isCustom).length;
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

    await _persistMetric(
      previousMetrics: _metrics,
      nextMetrics: _upsertMetric(_metrics, metric),
      metric: metric,
      errorMessage: 'Не удалось создать метрику.',
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

    await _persistMetric(
      previousMetrics: _metrics,
      nextMetrics: _upsertMetric(_metrics, updatedMetric),
      metric: updatedMetric,
      errorMessage: 'Не удалось обновить метрику.',
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
    await _persistMetric(
      previousMetrics: _metrics,
      nextMetrics: _upsertMetric(_metrics, updatedMetric),
      metric: updatedMetric,
      errorMessage: 'Не удалось сохранить значение метрики.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteMetric(HealthMetricItem metric) async {
    _isSaving = true;
    _errorMessage = null;
    final previousMetrics = _metrics;
    _setMetrics(_metrics.where((item) => item.id != metric.id).toList());
    notifyListeners();

    try {
      await _deleteMetric(metric.id);
      await _reloadFromCache();
    } catch (_) {
      _setMetrics(previousMetrics);
      _errorMessage = 'Не удалось удалить метрику.';
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  int countBySeverity(MetricSeverity severity) {
    return _metrics
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

  Future<void> _loadCached() async {
    try {
      _setMetrics(await _getCachedMetrics());
    } catch (_) {
      // Keep empty state if cache loading fails.
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistMetric({
    required List<HealthMetricItem> previousMetrics,
    required List<HealthMetricItem> nextMetrics,
    required HealthMetricItem metric,
    required String errorMessage,
    bool rethrowOnFailure = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _setMetrics(nextMetrics);
    notifyListeners();

    try {
      await _saveMetric(metric);
      await _reloadFromCache();
    } catch (_) {
      _setMetrics(previousMetrics);
      _errorMessage = errorMessage;
      if (rethrowOnFailure) {
        rethrow;
      }
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _reloadFromCache() async {
    _setMetrics(await _getCachedMetrics());
  }

  List<HealthMetricItem> _upsertMetric(
    List<HealthMetricItem> source,
    HealthMetricItem metric,
  ) {
    final updated = List<HealthMetricItem>.from(source);
    final index = updated.indexWhere((item) => item.id == metric.id);
    if (index == -1) {
      updated.add(metric);
    } else {
      updated[index] = metric;
    }

    _sortInPlace(updated);
    return updated;
  }

  void _setMetrics(List<HealthMetricItem> metrics) {
    _metrics = List<HealthMetricItem>.from(metrics);
    _sortInPlace(_metrics);
  }

  void _sortInPlace(List<HealthMetricItem> metrics) {
    metrics.sort((left, right) {
      if (left.isCustom != right.isCustom) {
        return left.isCustom ? 1 : -1;
      }
      return left.createdAt.compareTo(right.createdAt);
    });
  }
}
