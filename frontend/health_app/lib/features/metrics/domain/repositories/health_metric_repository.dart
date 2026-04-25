import '../entities/health_metric_item.dart';

abstract interface class HealthMetricRepository {
  Future<List<HealthMetricItem>> getMetrics();

  Future<void> saveMetric(HealthMetricItem metric);

  Future<void> deleteMetric(String metricId);
}
