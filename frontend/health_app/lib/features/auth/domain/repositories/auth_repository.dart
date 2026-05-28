import '../entities/auth_register_result.dart';
import '../entities/auth_session.dart';
import '../entities/saved_credentials.dart';

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<SavedCredentials> getSavedCredentials();

  Future<AuthRegisterResult> registerWithPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> confirmEmail({
    required String email,
    required String code,
  });

  Future<void> resendEmailConfirmation({required String email});

  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithProvider(AuthProvider provider);

  Future<void> requestPasswordReset({required String email});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> signOut();
}
