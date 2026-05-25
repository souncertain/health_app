import '../../../../core/network/api_exception.dart';
import '../../domain/entities/health_metric_item.dart';
import '../../domain/repositories/health_metric_repository.dart';
import '../datasources/health_metrics_local_data_source.dart';
import '../datasources/health_metrics_remote_data_source.dart';
import '../models/health_metric_model.dart';

class BackendHealthMetricRepository implements HealthMetricRepository {
  BackendHealthMetricRepository({
    required HealthMetricsLocalDataSource localDataSource,
    required HealthMetricsRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final HealthMetricsLocalDataSource _localDataSource;
  final HealthMetricsRemoteDataSource _remoteDataSource;

  @override
  Future<List<HealthMetricItem>> getCachedMetrics() async {
    return _sort(await _localDataSource.getMetrics());
  }

  @override
  Future<List<HealthMetricItem>> getMetrics() async {
    try {
      final remoteMetrics = await _remoteDataSource.getMetrics();
      final localMetrics = await _localDataSource.getMetrics();
      final merged = remoteMetrics
          .map((metric) => _mergeRemoteWithLocalIdentity(metric, localMetrics))
          .toList();

      await _localDataSource.saveAll(
        merged.map(HealthMetricModel.fromEntity).toList(),
      );
      return _sort(merged);
    } on ApiNetworkException {
      return _sort(await _localDataSource.getMetrics());
    }
  }

  @override
  Future<void> saveMetric(HealthMetricItem metric) async {
    final savedMetric =
        metric.remoteId == null || metric.remoteId!.trim().isEmpty
        ? await _remoteDataSource.createMetric(metric)
        : await _remoteDataSource.updateMetric(metric);

    final metricRemoteId = savedMetric.remoteId ?? savedMetric.id;
    final syncedRecords = <MetricRecord>[];
    for (final record in metric.records) {
      if (_looksLikeGuid(record.id)) {
        syncedRecords.add(
          await _remoteDataSource.updateRecord(
            recordRemoteId: record.id,
            healthMetricRemoteId: metricRemoteId,
            record: record,
          ),
        );
      } else {
        syncedRecords.add(
          await _remoteDataSource.createRecord(
            healthMetricRemoteId: metricRemoteId,
            record: record,
          ),
        );
      }
    }

    final syncedMetric = savedMetric.copyWith(
      id: metric.id,
      records: syncedRecords,
      remoteId: metricRemoteId,
      syncState: MetricSyncState.synced,
    );

    final metrics = await _localDataSource.getMetrics();
    final index = metrics.indexWhere((item) => item.id == metric.id);
    if (index == -1) {
      metrics.add(HealthMetricModel.fromEntity(syncedMetric));
    } else {
      metrics[index] = HealthMetricModel.fromEntity(syncedMetric);
    }

    await _localDataSource.saveAll(
      _sort(metrics).map(HealthMetricModel.fromEntity).toList(),
    );
  }

  @override
  Future<void> deleteMetric(String metricId) async {
    final metrics = await _localDataSource.getMetrics();
    final target = metrics
        .where((item) => item.id == metricId)
        .cast<HealthMetricItem?>()
        .firstWhere((item) => item != null, orElse: () => null);

    if (target == null) {
      return;
    }

    final remoteId = target.remoteId?.trim();
    if (remoteId != null && remoteId.isNotEmpty) {
      await _remoteDataSource.deleteMetric(remoteId);
    }

    metrics.removeWhere((item) => item.id == metricId);
    await _localDataSource.saveAll(metrics);
  }

  HealthMetricItem _mergeRemoteWithLocalIdentity(
    HealthMetricItem remoteMetric,
    List<HealthMetricModel> localMetrics,
  ) {
    final existing = localMetrics
        .where((item) => item.remoteId == remoteMetric.remoteId)
        .cast<HealthMetricItem?>()
        .firstWhere((item) => item != null, orElse: () => null);

    return remoteMetric.copyWith(id: existing?.id ?? remoteMetric.id);
  }

  List<HealthMetricItem> _sort(List<HealthMetricItem> metrics) {
    final sorted = List<HealthMetricItem>.from(metrics)
      ..sort((left, right) {
        if (left.isCustom != right.isCustom) {
          return left.isCustom ? 1 : -1;
        }
        return left.createdAt.compareTo(right.createdAt);
      });
    return sorted;
  }

  bool _looksLikeGuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
