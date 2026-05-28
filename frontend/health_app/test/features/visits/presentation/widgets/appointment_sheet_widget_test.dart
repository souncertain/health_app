import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/visits/domain/entities/medical_visit.dart';
import 'package:health_app/features/visits/presentation/widgets/appointment_sheet.dart';

import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Future<void> Function(AppointmentFormValue value) onSubmit,
    MedicalVisit? initialVisit,
  }) async {
    await pumpTestApp(
      tester,
      buildSheetLauncher(
        buttonLabel: 'Open',
        onOpen: (context) => showAppointmentSheet(
          context: context,
          onSubmit: onSubmit,
          initialVisit: initialVisit,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('submit requires selected time', (tester) async {
    await openSheet(tester, onSubmit: (_) async {});

    await tester.enterText(find.byType(TextFormField).at(0), 'Иван Петров');
    await tester.enterText(find.byType(TextFormField).at(1), 'Кардиолог');
    await tester.enterText(find.byType(TextFormField).at(2), 'Клиника');
    await tester.ensureVisible(find.text('Записаться'));
    await tester.tap(find.text('Записаться'));
    await tester.pumpAndSettle();

    expect(find.text('Выберите время приёма.'), findsOneWidget);
  });

  testWidgets('valid submit passes current visit type and normalized date', (tester) async {
    AppointmentFormValue? submitted;

    await openSheet(
      tester,
      initialVisit: sampleMedicalVisit(
        appointmentDate: DateTime(2026, 5, 26, 12),
        timeInMinutes: 600,
        visitType: MedicalVisitType.oneTime,
      ),
      onSubmit: (value) async {
        submitted = value;
      },
    );

    await tester.tap(find.text('Регулярный'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Обновить запись'));
    await tester.tap(find.text('Обновить запись'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.visitType, MedicalVisitType.recurring);
    expect(submitted!.appointmentDate, DateTime(2026, 5, 26));
    expect(submitted!.timeInMinutes, 600);
  });
}
