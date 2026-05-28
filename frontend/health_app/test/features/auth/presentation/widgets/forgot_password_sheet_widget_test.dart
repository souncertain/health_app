import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/domain/auth_exception.dart';
import 'package:health_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:health_app/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  late MockAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = MockAuthRepository();
    controller = AuthController(repository: repository);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await pumpTestApp(
      tester,
      buildSheetLauncher(
        buttonLabel: 'Open',
        onOpen: (context) => showForgotPasswordSheet(
          context,
          controller: controller,
          initialEmail: '',
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('request code validates email before submitting', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Send reset code'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    verifyNever(
      () => repository.requestPasswordReset(email: any(named: 'email')),
    );
  });

  testWidgets('successful request shows reset form', (tester) async {
    when(
      () => repository.requestPasswordReset(email: 'ivan@example.com'),
    ).thenAnswer((_) async {});

    await openSheet(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'ivan@example.com',
    );
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Update password'), findsOneWidget);
    expect(find.text('Reset code'), findsOneWidget);
  });

  testWidgets('password reset validates confirmation mismatch', (tester) async {
    when(
      () => repository.requestPasswordReset(email: 'ivan@example.com'),
    ).thenAnswer((_) async {});

    await openSheet(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'ivan@example.com',
    );
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret999');
    await tester.tap(find.text('Update password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('auth error during reset is shown to the user', (tester) async {
    when(
      () => repository.requestPasswordReset(email: 'ivan@example.com'),
    ).thenAnswer((_) async {});
    when(
      () => repository.resetPassword(
        email: 'ivan@example.com',
        code: '123456',
        newPassword: 'secret123',
      ),
    ).thenThrow(
      const AuthException('Validation failed', uiMessage: 'Код недействителен'),
    );

    await openSheet(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'ivan@example.com',
    );
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(find.text('Код недействителен'), findsOneWidget);
  });
}
