import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../models/provider_authorization_grant.dart';

class OAuthIdentityProvider {
  OAuthIdentityProvider({
    FlutterAppAuth? appAuth,
    GoogleSignIn? googleSignIn,
  }) : _appAuth = appAuth ?? const FlutterAppAuth(),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const ['email', 'profile', 'openid'],
             clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
             serverClientId: _googleServerClientId,
           );

  final FlutterAppAuth _appAuth;
  final GoogleSignIn _googleSignIn;

  static const _redirectUri = String.fromEnvironment(
    'AUTH_REDIRECT_URI',
    defaultValue: 'com.healthtrack.app:/oauth2redirect',
  );
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const _yandexClientId = String.fromEnvironment(
    'YANDEX_OAUTH_CLIENT_ID',
  );

  Future<ProviderAuthorizationGrant> authorize(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return _authorizeGoogle();
      case AuthProvider.yandex:
        return _authorizeYandex();
      case AuthProvider.password:
        throw const AuthException('This sign-in method does not use OAuth.');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      return;
    }
  }

  Future<ProviderAuthorizationGrant> _authorizeGoogle() async {
    if (_googleServerClientId.isEmpty) {
      throw const AuthException(
        'Set GOOGLE_SERVER_CLIENT_ID before using Google sign-in.',
      );
    }

    try {
      final account = await _googleSignIn
          .signIn()
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw const AuthException(
              'Google sign-in timed out before returning a credential.',
            ),
          );
      if (account == null) {
        throw const AuthException('Google sign-in was canceled.');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken?.trim() ?? '';

      if (idToken.isEmpty) {
        throw const AuthException(
          'Google did not return an ID token for backend sign-in.',
        );
      }

      return ProviderAuthorizationGrant(
        provider: AuthProvider.google,
        idToken: idToken,
        email: account.email.trim(),
        displayName: account.displayName?.trim(),
      );
    } on PlatformException catch (error) {
      final code = error.code.trim();
      final message = (error.message ?? '').trim();

      if (code == 'sign_in_canceled' ||
          code == 'network_error' && message.contains('canceled')) {
        throw const AuthException('Google sign-in was canceled.');
      }

      if (code == 'sign_in_failed' ||
          code == 'network_error' ||
          message.contains('10:') ||
          message.contains('12500') ||
          message.contains('12501')) {
        throw const AuthException(
          'Google sign-in is not configured correctly. Check client IDs, package name, SHA fingerprint, and the selected Google account.',
        );
      }

      throw AuthException(
        message.isNotEmpty ? message : 'Could not complete Google sign-in.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Could not complete Google sign-in.');
    }
  }

  Future<ProviderAuthorizationGrant> _authorizeYandex() async {
    if (_yandexClientId.isEmpty) {
      throw const AuthException(
        'Set YANDEX_OAUTH_CLIENT_ID before using Yandex sign-in.',
      );
    }

    try {
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

      final accessToken = response.accessToken?.trim() ?? '';
      if (accessToken.isEmpty) {
        throw const AuthException('Yandex did not return an access token.');
      }

      final claims = _decodeJwtClaims(response.idToken);
      final name = (claims?['name'] as String?)?.trim() ?? '';

      return ProviderAuthorizationGrant(
        provider: AuthProvider.yandex,
        accessToken: accessToken,
        email: (claims?['email'] as String?)?.trim(),
        displayName: name.isEmpty ? 'Yandex user' : name,
      );
    } on FlutterAppAuthUserCancelledException {
      throw const AuthException('Yandex sign-in was canceled.');
    } on FlutterAppAuthPlatformException catch (error) {
      final message = error.message?.trim() ?? '';
      throw AuthException(
        message.isNotEmpty
            ? message
            : 'Could not complete Yandex sign-in.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Could not complete Yandex sign-in.');
    }
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
}
