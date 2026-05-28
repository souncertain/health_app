import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/data/models/auth_session_model.dart';
import 'package:health_app/features/auth/domain/entities/auth_session.dart';

import '../../../../support/test_data.dart';

void main() {
  test('canEnterApp is true when access token exists', () {
    final session = sampleAuthSession(refreshToken: '', accessToken: 'token');

    expect(session.canEnterApp, isTrue);
  });

  test('canEnterApp is true when only refresh token exists', () {
    final session = sampleAuthSession(accessToken: '', refreshToken: 'token');

    expect(session.canEnterApp, isTrue);
  });

  test('AuthProvider label returns presentation text', () {
    expect(AuthProvider.password.label, 'Email');
    expect(AuthProvider.google.label, 'Google');
    expect(AuthProvider.yandex.label, 'Yandex');
  });

  test('AuthSessionModel round-trips through json', () {
    final session = sampleAuthSessionModel();

    final decoded = AuthSessionModel.fromJson(session.toJson());

    expect(decoded.userId, session.userId);
    expect(decoded.provider, session.provider);
    expect(decoded.refreshSessionId, session.refreshSessionId);
  });

  test('AuthSessionModel.fromJson falls back to password provider on unknown value', () {
    final session = AuthSessionModel.fromJson({
      'userId': 'user-1',
      'displayName': 'Ivan',
      'email': 'ivan@example.com',
      'provider': 'unknown',
      'accessToken': 'a',
      'refreshToken': 'b',
      'issuedAt': DateTime(2026, 5, 26).toIso8601String(),
    });

    expect(session.provider, AuthProvider.password);
  });

  test('AuthSessionModel.fromEntity copies values from base entity', () {
    final session = sampleAuthSession(provider: AuthProvider.google);

    final model = AuthSessionModel.fromEntity(session);

    expect(model.provider, AuthProvider.google);
    expect(model.email, session.email);
  });
}
