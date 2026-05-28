import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/domain/auth_exception.dart';
import 'package:health_app/features/auth/domain/entities/auth_session.dart';
import 'package:health_app/features/auth/domain/entities/saved_credentials.dart';
import 'package:health_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = MockAuthRepository();
    controller = AuthController(repository: repository);
  });

  test('initialize loads saved credentials and restored session', () async {
    final session = sampleAuthSession();
    when(() => repository.getSavedCredentials()).thenAnswer(
      (_) async => const SavedCredentials(email: 'ivan@example.com', password: ''),
    );
    when(() => repository.restoreSession()).thenAnswer((_) async => session);

    await controller.initialize();

    expect(controller.savedCredentials.email, 'ivan@example.com');
    expect(controller.session?.userId, session.userId);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.isLoading, isFalse);
  });

  test('initialize swallows restore failures and leaves session null', () async {
    when(() => repository.getSavedCredentials()).thenAnswer(
      (_) async => const SavedCredentials.empty(),
    );
    when(() => repository.restoreSession()).thenThrow(
      const AuthException('restore failed'),
    );

    await controller.initialize();

    expect(controller.session, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('signInWithPassword stores session and trimmed email', () async {
    final session = sampleAuthSession();
    when(
      () => repository.signInWithPassword(
        email: '  ivan@example.com  ',
        password: 'secret',
      ),
    ).thenAnswer((_) async => session);

    await controller.signInWithPassword(
      email: '  ivan@example.com  ',
      password: 'secret',
    );

    expect(controller.session?.userId, session.userId);
    expect(controller.savedCredentials.email, 'ivan@example.com');
    expect(controller.savedCredentials.password, isEmpty);
    expect(controller.isSubmitting, isFalse);
  });

  test('registerWithPassword stores pending confirmation email and trimmed email', () async {
    final pending = sampleAuthRegisterResult();
    when(
      () => repository.registerWithPassword(
        email: '  ivan@example.com  ',
        password: 'secret',
      ),
    ).thenAnswer((_) async => pending);

    final result = await controller.registerWithPassword(
      email: '  ivan@example.com  ',
      password: 'secret',
    );

    expect(result.emailConfirmationRequired, isTrue);
    expect(controller.session, isNull);
    expect(controller.pendingConfirmationEmail, 'ivan@example.com');
    expect(controller.savedCredentials.email, 'ivan@example.com');
  });

  test('confirmEmail stores session and clears pending confirmation email', () async {
    final session = sampleAuthSession();
    controller = AuthController(repository: repository);
    when(
      () => repository.confirmEmail(
        email: 'ivan@example.com',
        code: '123456',
      ),
    ).thenAnswer((_) async => session);

    await controller.confirmEmail(email: 'ivan@example.com', code: '123456');

    expect(controller.session?.userId, session.userId);
    expect(controller.pendingConfirmationEmail, isNull);
    expect(controller.savedCredentials.email, 'ivan@example.com');
  });

  test('resendEmailConfirmation delegates to repository and stores email', () async {
    when(() => repository.resendEmailConfirmation(email: 'ivan@example.com'))
        .thenAnswer((_) async {});

    await controller.resendEmailConfirmation(email: 'ivan@example.com');

    verify(() => repository.resendEmailConfirmation(email: 'ivan@example.com'))
        .called(1);
    expect(controller.pendingConfirmationEmail, 'ivan@example.com');
  });

  test('signInWithProvider updates session and clears saved credentials', () async {
    when(() => repository.signInWithProvider(AuthProvider.google)).thenAnswer(
      (_) async => sampleAuthSession(provider: AuthProvider.google),
    );

    await controller.signInWithProvider(AuthProvider.google);

    expect(controller.session?.provider, AuthProvider.google);
    expect(controller.savedCredentials.hasData, isFalse);
  });

  test('requestPasswordReset delegates to repository', () async {
    when(() => repository.requestPasswordReset(email: 'ivan@example.com'))
        .thenAnswer((_) async {});

    await controller.requestPasswordReset(email: 'ivan@example.com');

    verify(() => repository.requestPasswordReset(email: 'ivan@example.com'))
        .called(1);
    expect(controller.isSubmitting, isFalse);
  });

  test('resetPassword delegates to repository', () async {
    when(
      () => repository.resetPassword(
        email: 'ivan@example.com',
        code: '123456',
        newPassword: 'new-secret',
      ),
    ).thenAnswer((_) async {});

    await controller.resetPassword(
      email: 'ivan@example.com',
      code: '123456',
      newPassword: 'new-secret',
    );

    verify(
      () => repository.resetPassword(
        email: 'ivan@example.com',
        code: '123456',
        newPassword: 'new-secret',
      ),
    ).called(1);
  });

  test('signOut clears current session and saved credentials', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});
    controller = AuthController(repository: repository);
    when(() => repository.getSavedCredentials()).thenAnswer(
      (_) async => const SavedCredentials(email: 'ivan@example.com', password: ''),
    );
    when(() => repository.restoreSession()).thenAnswer(
      (_) async => sampleAuthSession(),
    );
    await controller.initialize();

    await controller.signOut();

    expect(controller.session, isNull);
    expect(controller.savedCredentials.hasData, isFalse);
    expect(controller.isSubmitting, isFalse);
  });
}
