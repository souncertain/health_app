import '../entities/auth_session.dart';
import '../entities/saved_credentials.dart';

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<SavedCredentials> getSavedCredentials();

  Future<AuthSession> registerWithPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithProvider(AuthProvider provider);

  Future<void> signOut();
}
