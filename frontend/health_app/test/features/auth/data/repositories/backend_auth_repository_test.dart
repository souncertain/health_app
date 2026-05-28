import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/data/models/provider_authorization_grant.dart';
import 'package:health_app/features/auth/data/models/auth_register_result_model.dart';
import 'package:health_app/features/auth/data/repositories/backend_auth_repository.dart';
import 'package:health_app/features/auth/domain/auth_exception.dart';
import 'package:health_app/features/auth/domain/entities/auth_session.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockAuthLocalDataSource localDataSource;
  late MockAuthRemoteDataSource remoteDataSource;
  late MockSecureCredentialsDataSource secureCredentialsDataSource;
  late MockAppSessionCleanupService appSessionCleanupService;
  late MockOAuthIdentityProvider oauthIdentityProvider;
  late BackendAuthRepository repository;

  setUp(() {
    localDataSource = MockAuthLocalDataSource();
    remoteDataSource = MockAuthRemoteDataSource();
    secureCredentialsDataSource = MockSecureCredentialsDataSource();
    appSessionCleanupService = MockAppSessionCleanupService();
    oauthIdentityProvider = MockOAuthIdentityProvider();
    repository = BackendAuthRepository(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      secureCredentialsDataSource: secureCredentialsDataSource,
      appSessionCleanupService: appSessionCleanupService,
      oauthIdentityProvider: oauthIdentityProvider,
    );
  });

  test('restoreSession returns null when no session is stored', () async {
    when(() => localDataSource.getSession()).thenAnswer((_) async => null);

    final session = await repository.restoreSession();

    expect(session, isNull);
  });

  test('restoreSession returns stored session when access token is still fresh', () async {
    final session = sampleAuthSessionModel(
      accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    when(() => localDataSource.getSession()).thenAnswer((_) async => session);

    final restored = await repository.restoreSession();

    expect(restored?.accessToken, session.accessToken);
    verifyNever(() => remoteDataSource.refresh(
          refreshToken: any(named: 'refreshToken'),
          refreshSessionId: any(named: 'refreshSessionId'),
        ));
  });

  test('restoreSession clears session when refresh fields are missing', () async {
    final session = sampleAuthSessionModel(
      accessToken: 'expired-token',
      refreshToken: '',
      refreshSessionId: null,
      accessTokenExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    when(() => localDataSource.getSession()).thenAnswer((_) async => session);
    when(() => localDataSource.clearSession()).thenAnswer((_) async {});

    final restored = await repository.restoreSession();

    expect(restored, isNull);
    verify(() => localDataSource.clearSession()).called(1);
  });

  test('restoreSession refreshes expired session and persists it', () async {
    final expired = sampleAuthSessionModel(
      accessTokenExpiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    final refreshed = sampleAuthSessionModel(
      accessToken: 'new-token',
      accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 2)),
    );
    when(() => localDataSource.getSession()).thenAnswer((_) async => expired);
    when(
      () => remoteDataSource.refresh(
        refreshToken: expired.refreshToken,
        refreshSessionId: expired.refreshSessionId!,
      ),
    ).thenAnswer((_) async => refreshed);
    when(() => localDataSource.saveSession(refreshed)).thenAnswer((_) async {});

    final restored = await repository.restoreSession();

    expect(restored?.accessToken, 'new-token');
    verify(() => localDataSource.saveSession(refreshed)).called(1);
  });

  test('restoreSession clears session when refresh throws AuthException', () async {
    final expired = sampleAuthSessionModel(
      accessTokenExpiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    when(() => localDataSource.getSession()).thenAnswer((_) async => expired);
    when(
      () => remoteDataSource.refresh(
        refreshToken: expired.refreshToken,
        refreshSessionId: expired.refreshSessionId!,
      ),
    ).thenThrow(const AuthException('expired'));
    when(() => localDataSource.clearSession()).thenAnswer((_) async {});

    final restored = await repository.restoreSession();

    expect(restored, isNull);
    verify(() => localDataSource.clearSession()).called(1);
  });

  test('signInWithPassword persists session and saved email', () async {
    final session = sampleAuthSessionModel();
    when(
      () => remoteDataSource.signIn(
        email: 'ivan@example.com',
        password: 'secret',
      ),
    ).thenAnswer((_) async => session);
    when(() => localDataSource.saveSession(session)).thenAnswer((_) async {});
    when(() => secureCredentialsDataSource.saveCredentials(email: 'ivan@example.com'))
        .thenAnswer((_) async {});

    final restored = await repository.signInWithPassword(
      email: 'ivan@example.com',
      password: 'secret',
    );

    expect(restored.accessToken, session.accessToken);
    verify(() => localDataSource.saveSession(session)).called(1);
    verify(() => secureCredentialsDataSource.saveCredentials(email: 'ivan@example.com'))
        .called(1);
  });

  test('registerWithPassword stores email and waits for confirmation', () async {
    const pending = AuthRegisterResultModel(
      email: 'ivan@example.com',
      emailConfirmationRequired: true,
    );
    when(
      () => remoteDataSource.register(
        email: 'ivan@example.com',
        password: 'secret',
      ),
    ).thenAnswer((_) async => pending);
    when(() => secureCredentialsDataSource.saveCredentials(email: 'ivan@example.com'))
        .thenAnswer((_) async {});

    final result = await repository.registerWithPassword(
      email: 'ivan@example.com',
      password: 'secret',
    );

    expect(result.emailConfirmationRequired, isTrue);
    verify(() => secureCredentialsDataSource.saveCredentials(email: 'ivan@example.com'))
        .called(1);
    verifyNever(() => localDataSource.saveSession(any()));
  });

  test('confirmEmail persists session and saved email', () async {
    final session = sampleAuthSessionModel();
    when(
      () => remoteDataSource.confirmEmail(
        email: 'ivan@example.com',
        code: '123456',
      ),
    ).thenAnswer((_) async => session);
    when(() => localDataSource.saveSession(session)).thenAnswer((_) async {});
    when(() => secureCredentialsDataSource.saveCredentials(email: 'ivan@example.com'))
        .thenAnswer((_) async {});

    final restored = await repository.confirmEmail(
      email: 'ivan@example.com',
      code: '123456',
    );

    expect(restored.accessToken, session.accessToken);
    verify(() => localDataSource.saveSession(session)).called(1);
    verify(() => secureCredentialsDataSource.saveCredentials(email: 'ivan@example.com'))
        .called(1);
  });

  test('resendEmailConfirmation delegates to remote data source', () async {
    when(() => remoteDataSource.resendEmailConfirmation(email: 'ivan@example.com'))
        .thenAnswer((_) async {});

    await repository.resendEmailConfirmation(email: 'ivan@example.com');

    verify(() => remoteDataSource.resendEmailConfirmation(email: 'ivan@example.com'))
        .called(1);
  });

  test('signInWithProvider uses google id token and clears credentials', () async {
    const grant = ProviderAuthorizationGrant(
      provider: AuthProvider.google,
      idToken: 'google-id-token',
    );
    final session = sampleAuthSessionModel(provider: AuthProvider.google);
    when(() => oauthIdentityProvider.authorize(AuthProvider.google)).thenAnswer(
      (_) async => grant,
    );
    when(() => remoteDataSource.signInWithGoogle(idToken: 'google-id-token'))
        .thenAnswer((_) async => session);
    when(() => localDataSource.saveSession(session)).thenAnswer((_) async {});
    when(() => secureCredentialsDataSource.clearCredentials())
        .thenAnswer((_) async {});

    final restored = await repository.signInWithProvider(AuthProvider.google);

    expect(restored.provider, AuthProvider.google);
    verify(() => remoteDataSource.signInWithGoogle(idToken: 'google-id-token'))
        .called(1);
    verify(() => secureCredentialsDataSource.clearCredentials()).called(1);
  });

  test('signInWithProvider uses yandex access token', () async {
    const grant = ProviderAuthorizationGrant(
      provider: AuthProvider.yandex,
      accessToken: 'ya-token',
    );
    final session = sampleAuthSessionModel(provider: AuthProvider.yandex);
    when(() => oauthIdentityProvider.authorize(AuthProvider.yandex)).thenAnswer(
      (_) async => grant,
    );
    when(() => remoteDataSource.signInWithYandex(accessToken: 'ya-token'))
        .thenAnswer((_) async => session);
    when(() => localDataSource.saveSession(session)).thenAnswer((_) async {});
    when(() => secureCredentialsDataSource.clearCredentials())
        .thenAnswer((_) async {});

    final restored = await repository.signInWithProvider(AuthProvider.yandex);

    expect(restored.provider, AuthProvider.yandex);
    verify(() => remoteDataSource.signInWithYandex(accessToken: 'ya-token'))
        .called(1);
  });

  test('signOut logs out remotely and clears all local auth state', () async {
    final session = sampleAuthSessionModel();
    when(() => localDataSource.getSession()).thenAnswer((_) async => session);
    when(
      () => remoteDataSource.logout(
        refreshToken: session.refreshToken,
        refreshSessionId: session.refreshSessionId!,
      ),
    ).thenAnswer((_) async {});
    when(() => localDataSource.clearSession()).thenAnswer((_) async {});
    when(() => secureCredentialsDataSource.clearCredentials())
        .thenAnswer((_) async {});
    when(() => appSessionCleanupService.clearUserScopedData())
        .thenAnswer((_) async {});
    when(() => oauthIdentityProvider.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(
      () => remoteDataSource.logout(
        refreshToken: session.refreshToken,
        refreshSessionId: session.refreshSessionId!,
      ),
    ).called(1);
    verify(() => localDataSource.clearSession()).called(1);
    verify(() => secureCredentialsDataSource.clearCredentials()).called(1);
    verify(() => appSessionCleanupService.clearUserScopedData()).called(1);
    verify(() => oauthIdentityProvider.signOut()).called(1);
  });

  test('signOut still clears local auth state when remote logout fails', () async {
    final session = sampleAuthSessionModel();
    when(() => localDataSource.getSession()).thenAnswer((_) async => session);
    when(
      () => remoteDataSource.logout(
        refreshToken: session.refreshToken,
        refreshSessionId: session.refreshSessionId!,
      ),
    ).thenThrow(Exception('network'));
    when(() => localDataSource.clearSession()).thenAnswer((_) async {});
    when(() => secureCredentialsDataSource.clearCredentials())
        .thenAnswer((_) async {});
    when(() => appSessionCleanupService.clearUserScopedData())
        .thenAnswer((_) async {});
    when(() => oauthIdentityProvider.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => localDataSource.clearSession()).called(1);
    verify(() => secureCredentialsDataSource.clearCredentials()).called(1);
    verify(() => appSessionCleanupService.clearUserScopedData()).called(1);
    verify(() => oauthIdentityProvider.signOut()).called(1);
  });
}
