import 'dart:convert';
import 'dart:math';

import 'package:flutter_appauth/flutter_appauth.dart';

import '../../domain/auth_exception.dart';
import '../../domain/entities/auth_session.dart';

class OAuthIdentityProvider {
  OAuthIdentityProvider({FlutterAppAuth? appAuth})
    : _appAuth = appAuth ?? const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  static const _redirectUri = String.fromEnvironment(
    'AUTH_REDIRECT_URI',
    defaultValue: 'com.healthtrack.app:/oauth2redirect',
  );
  static const _googleClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
  );
  static const _yandexClientId = String.fromEnvironment(
    'YANDEX_OAUTH_CLIENT_ID',
  );

  Future<AuthSession> signIn(AuthProvider provider) async {
    switch (provider) {
      case AuthProvider.google:
        return _signInGoogle();
      case AuthProvider.yandex:
        return _signInYandex();
      case AuthProvider.password:
        throw const AuthException('Этот способ не использует OAuth.');
    }
  }

  Future<AuthSession> _signInGoogle() async {
    if (_googleClientId.isEmpty) {
      throw const AuthException(
        'Для Google OAuth нужно указать GOOGLE_OAUTH_CLIENT_ID.',
      );
    }

    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _googleClientId,
        _redirectUri,
        discoveryUrl:
            'https://accounts.google.com/.well-known/openid-configuration',
        scopes: const ['openid', 'email', 'profile'],
        promptValues: const ['select_account'],
      ),
    );

    if (response.accessToken == null) {
      throw const AuthException('Не удалось завершить вход через Google.');
    }

    return _sessionFromTokenResponse(
      provider: AuthProvider.google,
      response: response,
      fallbackName: 'Пользователь Google',
    );
  }

  Future<AuthSession> _signInYandex() async {
    if (_yandexClientId.isEmpty) {
      throw const AuthException(
        'Для Яндекс OAuth нужно указать YANDEX_OAUTH_CLIENT_ID.',
      );
    }

    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _yandexClientId,
        _redirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://oauth.yandex.com/authorize',
          tokenEndpoint: 'https://oauth.yandex.com/token',
        ),
        scopes: const ['login:info', 'login:email'],
      ),
    );

    if (response.accessToken == null) {
      throw const AuthException('Не удалось завершить вход через Яндекс.');
    }

    return _sessionFromTokenResponse(
      provider: AuthProvider.yandex,
      response: response,
      fallbackName: 'Пользователь Яндекса',
    );
  }

  AuthSession _sessionFromTokenResponse({
    required AuthProvider provider,
    required AuthorizationTokenResponse response,
    required String fallbackName,
  }) {
    final claims = _decodeJwtClaims(response.idToken);
    final email = (claims?['email'] as String?)?.trim() ?? '';
    final name =
        ((claims?['name'] as String?) ??
                (claims?['given_name'] as String?) ??
                fallbackName)
            .trim();

    return AuthSession(
      userId: (claims?['sub'] as String?) ?? _randomIdentifier(),
      displayName: name.isEmpty ? fallbackName : name,
      email: email,
      provider: provider,
      accessToken: response.accessToken ?? '',
      refreshToken: response.refreshToken ?? '',
      issuedAt: DateTime.now(),
      accessTokenExpiresAt: response.accessTokenExpirationDateTime,
      refreshSessionId: response.refreshToken == null
          ? null
          : _randomIdentifier(),
    );
  }

  Map<String, dynamic>? _decodeJwtClaims(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _randomIdentifier() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
