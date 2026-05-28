import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/metrics/domain/entities/health_metric_item.dart';

import '../../../../support/test_data.dart';

void main() {
  test('recordsSortedAscending sorts by recordedOn ascending', () {
    final metric = sampleHealthMetric(
      records: [
        sampleMetricRecord(id: '2', recordedOn: DateTime(2026, 5, 26)),
        sampleMetricRecord(id: '1', recordedOn: DateTime(2026, 5, 24)),
      ],
    );

    expect(metric.recordsSortedAscending.map((item) => item.id), ['1', '2']);
  });

  test('recordsSortedDescending sorts by recordedOn descending', () {
    final metric = sampleHealthMetric(
      records: [
        sampleMetricRecord(id: '1', recordedOn: DateTime(2026, 5, 24)),
        sampleMetricRecord(id: '2', recordedOn: DateTime(2026, 5, 26)),
      ],
    );

    expect(metric.recordsSortedDescending.map((item) => item.id), ['2', '1']);
  });

  test('latestRecord returns most recent record', () {
    final latest = sampleMetricRecord(id: 'latest', recordedOn: DateTime(2026, 5, 26));
    final metric = sampleHealthMetric(
      records: [
        sampleMetricRecord(id: 'older', recordedOn: DateTime(2026, 5, 24)),
        latest,
      ],
    );

    expect(metric.latestRecord?.id, 'latest');
  });

  test('latestRecord returns null when metric has no records', () {
    final metric = sampleHealthMetric(records: const []);

    expect(metric.latestRecord, isNull);
  });

  test('recordForDate matches by normalized date', () {
    final record = sampleMetricRecord(
      recordedOn: DateTime(2026, 5, 26, 23, 59),
    );
    final metric = sampleHealthMetric(records: [record]);

    expect(metric.recordForDate(DateTime(2026, 5, 26, 8))?.id, record.id);
  });

  test('normalizeDate strips time component', () {
    expect(
      HealthMetricItem.normalizeDate(DateTime(2026, 5, 26, 12, 30)),
      DateTime(2026, 5, 26),
    );
  });

  test('copyWith updates selected fields', () {
    final metric = sampleHealthMetric(title: 'Before');

    final updated = metric.copyWith(title: 'After', targetMax: 10);

    expect(updated.title, 'After');
    expect(updated.targetMax, 10);
    expect(updated.unit, metric.unit);
  });
}
