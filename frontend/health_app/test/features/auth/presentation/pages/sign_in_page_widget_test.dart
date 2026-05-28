import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/domain/auth_exception.dart';
import 'package:health_app/features/auth/domain/entities/auth_session.dart';
import 'package:health_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:health_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  late MockAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = MockAuthRepository();
    controller = AuthController(repository: repository);
  });

  testWidgets('sign in validates empty email and password', (tester) async {
    await pumpTestApp(tester, SignInPage(controller: controller));

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsAtLeastNWidgets(1));
    expect(find.text('Enter your password'), findsAtLeastNWidgets(1));
  });

  testWidgets('successful sign in submits trimmed email to controller', (
    tester,
  ) async {
    when(
      () => repository.signInWithPassword(
        email: 'ivan@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async => sampleAuthSession());

    await pumpTestApp(tester, SignInPage(controller: controller));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  ivan@example.com  ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    verify(
      () => repository.signInWithPassword(
        email: 'ivan@example.com',
        password: 'secret123',
      ),
    ).called(1);
  });

  testWidgets('auth error from sign in is shown in snackbar', (tester) async {
    when(
      () => repository.signInWithPassword(
        email: 'ivan@example.com',
        password: 'secret123',
      ),
    ).thenThrow(
      const AuthException('Request failed', uiMessage: 'Неверный пароль'),
    );

    await pumpTestApp(tester, SignInPage(controller: controller));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ivan@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный пароль'), findsOneWidget);
  });

  testWidgets('tapping forgot password opens reset sheet', (tester) async {
    await pumpTestApp(tester, SignInPage(controller: controller));

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot password'), findsOneWidget);
    expect(find.text('Send reset code'), findsOneWidget);
  });

  testWidgets('google provider button triggers provider sign in', (tester) async {
    when(() => repository.signInWithProvider(AuthProvider.google)).thenAnswer(
      (_) async => sampleAuthSession(provider: AuthProvider.google),
    );

    await pumpTestApp(tester, SignInPage(controller: controller));

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    verify(() => repository.signInWithProvider(AuthProvider.google)).called(1);
  });
}
