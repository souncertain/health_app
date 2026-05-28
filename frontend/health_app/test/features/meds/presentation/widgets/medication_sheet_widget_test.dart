import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/widgets/app_form_sheet.dart';
import 'package:health_app/features/meds/domain/entities/medication.dart';
import 'package:health_app/features/meds/presentation/widgets/medication_sheet.dart';

import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    Medication? initialMedication,
    required Future<void> Function(MedicationFormValue value) onSubmit,
    Future<void> Function()? onDelete,
  }) async {
    await pumpTestApp(
      tester,
      buildSheetLauncher(
        buttonLabel: 'Open',
        onOpen: (context) => showMedicationSheet(
          context: context,
          selectedWeekday: DateTime.monday,
          initialMedication: initialMedication,
          onSubmit: onSubmit,
          onDelete: onDelete,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('frequency selection updates the number of time fields', (tester) async {
    await openSheet(tester, onSubmit: (_) async {});

    await tester.tap(find.text('3 раза в день'));
    await tester.pumpAndSettle();

    expect(find.byType(AppPickerField), findsNWidgets(3));
  });

  testWidgets('duplicate times are rejected with user-facing error', (tester) async {
    await openSheet(
      tester,
      initialMedication: sampleMedication(
        frequency: MedicationFrequency.twiceDaily,
        timesInMinutes: const [480, 480],
      ),
      onSubmit: (_) async {},
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Аспирин');
    await tester.enterText(find.byType(TextFormField).at(1), '10 мг');
    await tester.tap(find.text('Обновить препарат'));
    await tester.pumpAndSettle();

    expect(find.text('Время приема не должно повторяться.'), findsOneWidget);
  });

  testWidgets('successful submit passes trimmed values and sorted times', (tester) async {
    MedicationFormValue? submitted;

    await openSheet(
      tester,
      initialMedication: sampleMedication(
        frequency: MedicationFrequency.twiceDaily,
        timesInMinutes: const [900, 480],
      ),
      onSubmit: (value) async {
        submitted = value;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), '  Аспирин  ');
    await tester.enterText(find.byType(TextFormField).at(1), ' 10 мг ');
    await tester.tap(find.text('Обновить препарат'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.name, 'Аспирин');
    expect(submitted!.dosage, '10 мг');
    expect(submitted!.timesInMinutes, [480, 900]);
  });
}
