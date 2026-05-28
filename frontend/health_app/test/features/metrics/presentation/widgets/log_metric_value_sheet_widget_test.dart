import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/metrics/presentation/widgets/log_metric_value_sheet.dart';

import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Future<void> Function(LogMetricValueFormValue value) onSubmit,
  }) async {
    await pumpTestApp(
      tester,
      buildSheetLauncher(
        buttonLabel: 'Open',
        onOpen: (context) => showLogMetricValueSheet(
          context: context,
          metric: sampleHealthMetric(
            title: 'Глюкоза',
            unit: 'ммоль/л',
            records: [
              sampleMetricRecord(
                value: 5.5,
                recordedOn: DateTime.now(),
              ),
            ],
          ),
          onSubmit: onSubmit,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('existing value warning is shown for selected date', (tester) async {
    await openSheet(tester, onSubmit: (_) async {});

    expect(
      find.textContaining('На эту дату уже есть сохраненное значение'),
      findsOneWidget,
    );
  });

  testWidgets('valid submit passes parsed value and normalized date', (tester) async {
    LogMetricValueFormValue? submitted;

    await openSheet(
      tester,
      onSubmit: (value) async {
        submitted = value;
      },
    );

    await tester.enterText(find.byType(TextFormField).first, '6,4');
    await tester.tap(find.text('Сохранить значение'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.value, 6.4);
    expect(
      submitted!.recordedOn,
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
  });
}
