import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/metrics/presentation/pages/metrics_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  late MockHealthMetricRepository repository;

  setUp(() {
    repository = MockHealthMetricRepository();
  });

  testWidgets('renders empty state when there are no metrics', (tester) async {
    when(() => repository.getCachedMetrics()).thenAnswer((_) async => const []);
    when(() => repository.getMetrics()).thenAnswer((_) async => const []);

    await pumpTestApp(tester, MetricsPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Метрик пока нет'), findsOneWidget);
    expect(find.text('Создать метрику'), findsAtLeastNWidgets(1));
  });

  testWidgets('renders metric title and allows expansion tap', (tester) async {
    final metric = sampleHealthMetric(
      title: 'Глюкоза',
      records: [sampleMetricRecord(value: 5.5)],
    );
    when(() => repository.getCachedMetrics()).thenAnswer((_) async => [metric]);
    when(() => repository.getMetrics()).thenAnswer((_) async => [metric]);

    await pumpTestApp(tester, MetricsPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Глюкоза'), findsOneWidget);
    await tester.tap(find.text('Глюкоза'));
    await tester.pumpAndSettle();

    expect(find.text('История за 7 дней'), findsOneWidget);
    expect(find.text('Записать значение'), findsOneWidget);
  });
}
