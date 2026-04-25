import '../../domain/entities/health_metric_item.dart';
import '../../domain/repositories/health_metric_repository.dart';
import '../datasources/health_metrics_local_data_source.dart';
import '../models/health_metric_model.dart';

class LocalHealthMetricRepository implements HealthMetricRepository {
  const LocalHealthMetricRepository(this._localDataSource);

  final HealthMetricsLocalDataSource _localDataSource;

  @override
  Future<List<HealthMetricItem>> getMetrics() async {
    final metrics = await _localDataSource.getMetrics();
    metrics.sort(_sortMetrics);
    return metrics;
  }

  @override
  Future<void> saveMetric(HealthMetricItem metric) async {
    final metrics = await _localDataSource.getMetrics();
    final model = HealthMetricModel.fromEntity(metric);
    final index = metrics.indexWhere((item) => item.id == metric.id);

    if (index == -1) {
      metrics.add(model);
    } else {
      metrics[index] = model;
    }

    metrics.sort(_sortMetrics);
    await _localDataSource.saveAll(metrics);
  }

  @override
  Future<void> deleteMetric(String metricId) async {
    final metrics = await _localDataSource.getMetrics();
    metrics.removeWhere((item) => item.id == metricId);
    metrics.sort(_sortMetrics);
    await _localDataSource.saveAll(metrics);
  }

  int _sortMetrics(HealthMetricItem left, HealthMetricItem right) {
    if (left.isCustom != right.isCustom) {
      return left.isCustom ? 1 : -1;
    }
    return left.createdAt.compareTo(right.createdAt);
  }
}
