import '../../../../core/services/app_session_cleanup_service.dart';
import '../../domain/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/saved_credentials.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/secure_credentials_data_source.dart';
import '../models/auth_session_model.dart';

class BackendAuthRepository implements AuthRepository {
  BackendAuthRepository({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
    required SecureCredentialsDataSource secureCredentialsDataSource,
    required AppSessionCleanupService appSessionCleanupService,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _secureCredentialsDataSource = secureCredentialsDataSource,
       _appSessionCleanupService = appSessionCleanupService;

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final SecureCredentialsDataSource _secureCredentialsDataSource;
  final AppSessionCleanupService _appSessionCleanupService;

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _localDataSource.getSession();
    if (session == null || !session.canEnterApp) {
      return null;
    }

    if (_hasFreshAccessToken(session)) {
      return session;
    }

    final refreshSessionId = session.refreshSessionId?.trim() ?? '';
    final refreshToken = session.refreshToken.trim();
    if (refreshSessionId.isEmpty || refreshToken.isEmpty) {
      await _localDataSource.clearSession();
      return null;
    }

    try {
      final refreshed = await _remoteDataSource.refresh(
        refreshToken: refreshToken,
        refreshSessionId: refreshSessionId,
      );
      await _localDataSource.saveSession(refreshed);
      return refreshed;
    } on AuthException {
      await _localDataSource.clearSession();
      return null;
    }
  }

  @override
  Future<SavedCredentials> getSavedCredentials() {
    return _secureCredentialsDataSource.readCredentials();
  }

  @override
  Future<AuthSession> registerWithPassword({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.register(
      email: email,
      password: password,
    );

    await _persistSuccessfulPasswordAuth(
      session: session,
      email: email,
      password: password,
    );
    return session;
  }

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.signIn(
      email: email,
      password: password,
    );

    await _persistSuccessfulPasswordAuth(
      session: session,
      email: email,
      password: password,
    );
    return session;
  }

  @override
  Future<AuthSession> signInWithProvider(AuthProvider provider) {
    throw const AuthException(
      'Google and Yandex sign-in will be connected next. For now, use email and password.',
    );
  }

  @override
  Future<void> signOut() async {
    final session = await _localDataSource.getSession();

    try {
      final refreshSessionId = session?.refreshSessionId?.trim() ?? '';
      final refreshToken = session?.refreshToken.trim() ?? '';
      if (refreshSessionId.isNotEmpty && refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(
          refreshToken: refreshToken,
          refreshSessionId: refreshSessionId,
        );
      }
    } catch (_) {
      // Local sign-out should still succeed even if backend logout is unavailable.
    } finally {
      await Future.wait([
        _localDataSource.clearSession(),
        _secureCredentialsDataSource.clearCredentials(),
        _appSessionCleanupService.clearUserScopedData(),
      ]);
    }
  }

  Future<void> _persistSuccessfulPasswordAuth({
    required AuthSessionModel session,
    required String email,
    required String password,
  }) async {
    await _localDataSource.saveSession(session);
    await _secureCredentialsDataSource.saveCredentials(
      email: email.trim(),
      password: password,
    );
  }

  bool _hasFreshAccessToken(AuthSession session) {
    final accessToken = session.accessToken.trim();
    if (accessToken.isEmpty) {
      return false;
    }

    final expiresAt = session.accessTokenExpiresAt;
    if (expiresAt == null) {
      return true;
    }

    return expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 30)));
  }
}
