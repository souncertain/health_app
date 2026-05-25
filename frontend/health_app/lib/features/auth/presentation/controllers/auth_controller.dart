import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/saved_credentials.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  AuthSession? _session;
  SavedCredentials _savedCredentials = const SavedCredentials.empty();
  bool _isLoading = true;
  bool _isSubmitting = false;

  AuthSession? get session => _session;
  SavedCredentials get savedCredentials => _savedCredentials;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _session?.canEnterApp ?? false;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedCredentials = await _repository.getSavedCredentials();
      _session = await _repository.restoreSession();
    } catch (_) {
      _session = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _session = await _repository.signInWithPassword(
        email: email,
        password: password,
      );
      _savedCredentials = SavedCredentials(
        email: email.trim(),
        password: password,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> registerWithPassword({
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _session = await _repository.registerWithPassword(
        email: email,
        password: password,
      );
      _savedCredentials = SavedCredentials(
        email: email.trim(),
        password: password,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signInWithProvider(AuthProvider provider) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _session = await _repository.signInWithProvider(provider);
      _savedCredentials = const SavedCredentials.empty();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.requestPasswordReset(email: email);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.signOut();
      _session = null;
      _savedCredentials = const SavedCredentials.empty();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
