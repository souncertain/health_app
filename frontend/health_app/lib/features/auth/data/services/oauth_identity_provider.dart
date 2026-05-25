import 'dart:convert';

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
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FlutterAppAuth _appAuth;
  final GoogleSignIn _googleSignIn;

  bool _isGoogleInitialized = false;

  static const _redirectUri = String.fromEnvironment(
    'AUTH_REDIRECT_URI',
    defaultValue: 'com.healthtrack.app:/oauth2redirect',
  );
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
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
      if (_isGoogleInitialized) {
        await _googleSignIn.signOut();
      }
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
      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final authentication = account.authentication;
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
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw const AuthException('Google sign-in was canceled.');
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw const AuthException(
            'Google sign-in is not configured correctly. Check client IDs, package name, and SHA fingerprint.',
          );
        default:
          final description = error.description?.trim() ?? '';
          throw AuthException(
            description.isNotEmpty
                ? description
                : 'Could not complete Google sign-in.',
          );
      }
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

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) {
      return;
    }

    await _googleSignIn.initialize(
      clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
      serverClientId: _googleServerClientId,
    );
    _isGoogleInitialized = true;
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
