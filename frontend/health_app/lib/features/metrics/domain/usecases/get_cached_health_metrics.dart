import '../entities/health_metric_item.dart';
import '../repositories/health_metric_repository.dart';

class GetCachedHealthMetricsUseCase {
  const GetCachedHealthMetricsUseCase(this._repository);

  final HealthMetricRepository _repository;

  Future<List<HealthMetricItem>> call() {
    return _repository.getCachedMetrics();
  }
}
