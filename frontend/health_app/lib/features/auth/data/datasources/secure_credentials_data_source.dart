import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/saved_credentials.dart';

class SecureCredentialsDataSource {
  SecureCredentialsDataSource({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _emailKey = 'auth.saved_email';
  static const _passwordKey = 'auth.saved_password';

  final FlutterSecureStorage _storage;

  Future<SavedCredentials> readCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey) ?? '';
      final password = await _storage.read(key: _passwordKey) ?? '';
      return SavedCredentials(email: email, password: password);
    } on MissingPluginException {
      return const SavedCredentials.empty();
    } catch (_) {
      return const SavedCredentials.empty();
    }
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }
}
