import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';
import 'package:health_app/features/profile/presentation/widgets/profile_edit_sheet.dart';

import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Future<void> Function(UserProfile profile) onSubmit,
  }) async {
    await pumpTestApp(
      tester,
      buildSheetLauncher(
        buttonLabel: 'Open',
        onOpen: (context) => showProfileEditSheet(
          context: context,
          initialProfile: sampleUserProfile(),
          onSubmit: onSubmit,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('positive number validators show readable messages', (tester) async {
    await openSheet(tester, onSubmit: (_) async {});

    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.enterText(find.byType(TextFormField).at(4), '-1');
    await tester.enterText(find.byType(TextFormField).at(5), 'abc');
    await tester.ensureVisible(find.text('Сохранить профиль'));
    await tester.tap(find.text('Сохранить профиль'));
    await tester.pump();

    expect(
      find.text('Значение должно быть больше нуля'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('Введите число'), findsAtLeastNWidgets(1));
  });

  testWidgets('successful submit trims text and clears blank optional fields', (tester) async {
    UserProfile? submitted;

    await openSheet(
      tester,
      onSubmit: (profile) async {
        submitted = profile;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), '  Иван Петров  ');
    await tester.enterText(find.byType(TextFormField).at(6), '   ');
    await tester.enterText(find.byType(TextFormField).at(7), '  Мария  ');
    await tester.enterText(find.byType(TextFormField).at(8), '  +7999  ');
    await tester.ensureVisible(find.text('Сохранить профиль'));
    await tester.tap(find.text('Сохранить профиль'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.fullName, 'Иван Петров');
    expect(submitted!.primaryDoctor, isNull);
    expect(submitted!.emergencyContactName, 'Мария');
    expect(submitted!.emergencyContactDetails, '+7999');
  });
}
