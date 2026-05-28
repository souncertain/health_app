import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/metrics/presentation/widgets/custom_metric_sheet.dart';

import '../../../../support/widget_test_helpers.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Future<void> Function(CustomMetricFormValue value) onSubmit,
    CustomMetricFormValue? initialValue,
  }) async {
    await pumpTestApp(
      tester,
      buildSheetLauncher(
        buttonLabel: 'Open',
        onOpen: (context) => showCustomMetricSheet(
          context: context,
          onSubmit: onSubmit,
          initialValue: initialValue,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('target max must be greater than target min', (tester) async {
    await openSheet(tester, onSubmit: (_) async {});

    await tester.enterText(find.byType(TextFormField).at(0), 'Глюкоза');
    await tester.enterText(find.byType(TextFormField).at(1), 'ммоль/л');
    await tester.enterText(find.byType(TextFormField).at(2), '7');
    await tester.enterText(find.byType(TextFormField).at(3), '7');
    await tester.tap(find.text('Создать метрику'));
    await tester.pumpAndSettle();

    expect(
      find.text('Верхняя граница должна быть больше нижней.'),
      findsOneWidget,
    );
  });

  testWidgets('valid submit parses decimal values and closes sheet', (tester) async {
    CustomMetricFormValue? submitted;

    await openSheet(
      tester,
      onSubmit: (value) async {
        submitted = value;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Глюкоза');
    await tester.enterText(find.byType(TextFormField).at(1), 'ммоль/л');
    await tester.enterText(find.byType(TextFormField).at(2), '3,5');
    await tester.enterText(find.byType(TextFormField).at(3), '7,2');
    await tester.tap(find.text('Создать метрику'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.name, 'Глюкоза');
    expect(submitted!.targetMin, 3.5);
    expect(submitted!.targetMax, 7.2);
  });
}
