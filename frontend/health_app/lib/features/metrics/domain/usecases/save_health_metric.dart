import '../entities/health_metric_item.dart';
import '../repositories/health_metric_repository.dart';

class SaveHealthMetricUseCase {
  const SaveHealthMetricUseCase(this._repository);

  final HealthMetricRepository _repository;

  Future<void> call(HealthMetricItem metric) {
    return _repository.saveMetric(metric);
  }
}
