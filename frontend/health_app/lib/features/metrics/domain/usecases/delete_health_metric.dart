import '../repositories/health_metric_repository.dart';

class DeleteHealthMetricUseCase {
  const DeleteHealthMetricUseCase(this._repository);

  final HealthMetricRepository _repository;

  Future<void> call(String metricId) {
    return _repository.deleteMetric(metricId);
  }
}
