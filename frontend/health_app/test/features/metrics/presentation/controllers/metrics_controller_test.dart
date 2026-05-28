import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/metrics/domain/entities/health_metric_item.dart';
import 'package:health_app/features/metrics/domain/usecases/delete_health_metric.dart';
import 'package:health_app/features/metrics/domain/usecases/get_cached_health_metrics.dart';
import 'package:health_app/features/metrics/domain/usecases/get_health_metrics.dart';
import 'package:health_app/features/metrics/domain/usecases/save_health_metric.dart';
import 'package:health_app/features/metrics/presentation/controllers/metrics_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockHealthMetricRepository repository;
  late MetricsController controller;

  setUp(() {
    repository = MockHealthMetricRepository();
    when(() => repository.getCachedMetrics()).thenAnswer((_) async => const []);
    when(() => repository.getMetrics()).thenAnswer((_) async => const []);
    controller = MetricsController(
      getCachedMetrics: GetCachedHealthMetricsUseCase(repository),
      getMetrics: GetHealthMetricsUseCase(repository),
      saveMetric: SaveHealthMetricUseCase(repository),
      deleteMetric: DeleteHealthMetricUseCase(repository),
    );
  });

  Future<void> seedMetrics(List<HealthMetricItem> metrics) async {
    when(() => repository.getCachedMetrics()).thenAnswer((_) async => metrics);
    when(() => repository.getMetrics()).thenAnswer((_) async => metrics);
    await controller.initialize();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('createCustomMetric persists a custom metric with rotating style', () async {
    when(() => repository.saveMetric(any())).thenAnswer((_) async {});

    final id = await controller.createCustomMetric(
      title: 'Hydration',
      unit: 'ml',
      targetMin: 1,
      targetMax: 2,
    );

    final captured =
        verify(() => repository.saveMetric(captureAny())).captured.single
            as HealthMetricItem;
    expect(id, captured.id);
    expect(captured.isCustom, isTrue);
    expect(captured.visualStyle, MetricVisualStyle.emeraldPulse);
  });

  test('updateMetricDetails persists updated metric values', () async {
    final metric = sampleHealthMetric(title: 'Sugar');
    await seedMetrics([metric]);
    when(() => repository.saveMetric(any())).thenAnswer((_) async {});

    await controller.updateMetricDetails(
      metric: metric,
      title: 'Glucose',
      unit: 'mmol/L',
      targetMin: 4,
      targetMax: 7,
    );

    final captured =
        verify(() => repository.saveMetric(captureAny())).captured.single
            as HealthMetricItem;
    expect(captured.title, 'Glucose');
    expect(captured.unit, 'mmol/L');
  });

  test('logMetricValue adds new record when date has no record yet', () async {
    final metric = sampleHealthMetric(records: const []);
    await seedMetrics([metric]);
    when(() => repository.saveMetric(any())).thenAnswer((_) async {});

    await controller.logMetricValue(
      metric: metric,
      value: 7,
      recordedOn: DateTime(2026, 5, 26, 15),
    );

    final captured =
        verify(() => repository.saveMetric(captureAny())).captured.single
            as HealthMetricItem;
    expect(captured.records, hasLength(1));
    expect(captured.records.single.recordedOn, DateTime(2026, 5, 26));
  });

  test('logMetricValue updates existing record on same date', () async {
    final existing = sampleMetricRecord(
      id: 'record-1',
      value: 5,
      recordedOn: DateTime(2026, 5, 26),
    );
    final metric = sampleHealthMetric(records: [existing]);
    await seedMetrics([metric]);
    when(() => repository.saveMetric(any())).thenAnswer((_) async {});

    await controller.logMetricValue(
      metric: metric,
      value: 8,
      recordedOn: DateTime(2026, 5, 26, 20),
    );

    final captured =
        verify(() => repository.saveMetric(captureAny())).captured.single
            as HealthMetricItem;
    expect(captured.records, hasLength(1));
    expect(captured.records.single.value, 8);
    expect(captured.records.single.id, 'record-1');
  });

  test('severityForMetric handles noData normal monitor and critical states', () {
    expect(
      controller.severityForMetric(sampleHealthMetric(records: const [])),
      MetricSeverity.noData,
    );
    expect(
      controller.severityForMetric(
        sampleHealthMetric(records: [sampleMetricRecord(value: 5)]),
      ),
      MetricSeverity.normal,
    );
    expect(
      controller.severityForMetric(
        sampleHealthMetric(records: [sampleMetricRecord(value: 6.2)]),
      ),
      MetricSeverity.monitor,
    );
    expect(
      controller.severityForMetric(
        sampleHealthMetric(records: [sampleMetricRecord(value: 10)]),
      ),
      MetricSeverity.critical,
    );
  });

  test('trendForMetric handles none stable up and down trends', () {
    expect(
      controller.trendForMetric(sampleHealthMetric(records: const [])),
      MetricTrend.none,
    );
    expect(
      controller.trendForMetric(
        sampleHealthMetric(
          records: [
            sampleMetricRecord(value: 5, recordedOn: DateTime(2026, 5, 25)),
            sampleMetricRecord(value: 5.005, recordedOn: DateTime(2026, 5, 26)),
          ],
        ),
      ),
      MetricTrend.stable,
    );
    expect(
      controller.trendForMetric(
        sampleHealthMetric(
          records: [
            sampleMetricRecord(value: 5, recordedOn: DateTime(2026, 5, 25)),
            sampleMetricRecord(value: 6, recordedOn: DateTime(2026, 5, 26)),
          ],
        ),
      ),
      MetricTrend.up,
    );
    expect(
      controller.trendForMetric(
        sampleHealthMetric(
          records: [
            sampleMetricRecord(value: 6, recordedOn: DateTime(2026, 5, 25)),
            sampleMetricRecord(value: 5, recordedOn: DateTime(2026, 5, 26)),
          ],
        ),
      ),
      MetricTrend.down,
    );
  });

  test('progressForMetric clamps values to 0..1', () {
    expect(
      controller.progressForMetric(
        sampleHealthMetric(records: [sampleMetricRecord(value: 1)]),
      ),
      0,
    );
    expect(
      controller.progressForMetric(
        sampleHealthMetric(records: [sampleMetricRecord(value: 10)]),
      ),
      1,
    );
  });

  test('historyForMetric builds 7-day history ending today', () {
    final today = DateTime.now();
    final metric = sampleHealthMetric(
      records: [
        sampleMetricRecord(
          value: 5,
          recordedOn: DateTime(today.year, today.month, today.day),
        ),
      ],
    );

    final history = controller.historyForMetric(metric);

    expect(history, hasLength(7));
    expect(history.last.value, 5);
  });

  test('sparklineValuesForMetric returns normalized values when enough data exists', () {
    final metric = sampleHealthMetric(
      records: [
        sampleMetricRecord(value: 5, recordedOn: DateTime.now().subtract(const Duration(days: 2))),
        sampleMetricRecord(value: 7, recordedOn: DateTime.now().subtract(const Duration(days: 1))),
      ],
    );

    final values = controller.sparklineValuesForMetric(metric);

    expect(values, hasLength(2));
    expect(values.first, 0);
    expect(values.last, 1);
  });

  test('hasRenderableHistory requires at least two data points', () {
    final today = DateTime.now();

    expect(
      controller.hasRenderableHistory(
        sampleHealthMetric(records: [sampleMetricRecord(value: 5)]),
      ),
      isFalse,
    );
    expect(
      controller.hasRenderableHistory(
        sampleHealthMetric(
          records: [
            sampleMetricRecord(
              id: 'record-1',
              value: 5,
              recordedOn: DateTime(today.year, today.month, today.day - 1),
            ),
            sampleMetricRecord(
              id: 'record-2',
              value: 6,
              recordedOn: DateTime(today.year, today.month, today.day),
            ),
          ],
        ),
      ),
      isTrue,
    );
  });
}
