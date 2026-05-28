import 'dart:convert';
import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../domain/auth_exception.dart';
import '../models/auth_register_result_model.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({HttpClient? httpClient})
    : _httpClient = httpClient ?? _sharedHttpClient;

  final HttpClient _httpClient;

  static final HttpClient _sharedHttpClient = () {
    final client = HttpClient();
    client.idleTimeout = const Duration(minutes: 2);
    client.connectionTimeout = const Duration(seconds: 10);
    client.maxConnectionsPerHost = 4;
    return client;
  }();

  Future<AuthRegisterResultModel> register({
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      path: '/api/auth/register',
      payload: {'email': email.trim(), 'password': password},
    );
    return AuthRegisterResultModel.fromJson(json);
  }

  Future<AuthSessionModel> confirmEmail({
    required String email,
    required String code,
  }) {
    return _postSession(
      path: '/api/auth/confirm-email',
      payload: {'email': email.trim(), 'code': code.trim()},
    );
  }

  Future<void> resendEmailConfirmation({required String email}) {
    return _postWithoutResponse(
      path: '/api/auth/resend-confirmation',
      payload: {'email': email.trim()},
    );
  }

  Future<AuthSessionModel> signIn({
    required String email,
    required String password,
  }) {
    return _postSession(
      path: '/api/auth/login',
      payload: {'email': email.trim(), 'password': password},
    );
  }

  Future<AuthSessionModel> signInWithGoogle({
    required String idToken,
    String? deviceId,
    String? deviceName,
  }) {
    return _postSession(
      path: '/api/auth/google',
      payload: {
        'idToken': idToken.trim(),
        if (deviceId?.trim().isNotEmpty ?? false) 'deviceId': deviceId!.trim(),
        if (deviceName?.trim().isNotEmpty ?? false)
          'deviceName': deviceName!.trim(),
      },
    );
  }

  Future<AuthSessionModel> signInWithYandex({
    required String accessToken,
    String? deviceId,
    String? deviceName,
  }) {
    return _postSession(
      path: '/api/auth/yandex',
      payload: {
        'accessToken': accessToken.trim(),
        if (deviceId?.trim().isNotEmpty ?? false) 'deviceId': deviceId!.trim(),
        if (deviceName?.trim().isNotEmpty ?? false)
          'deviceName': deviceName!.trim(),
      },
    );
  }

  Future<AuthSessionModel> refresh({
    required String refreshToken,
    required String refreshSessionId,
  }) {
    return _postSession(
      path: '/api/auth/refresh',
      payload: {
        'refreshToken': refreshToken,
        'refreshSessionId': refreshSessionId,
      },
    );
  }

  Future<void> requestPasswordReset({required String email}) {
    return _postWithoutResponse(
      path: '/api/auth/forgot-password',
      payload: {'email': email.trim()},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _postWithoutResponse(
      path: '/api/auth/reset-password',
      payload: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout({
    required String refreshToken,
    required String refreshSessionId,
  }) {
    return _postWithoutResponse(
      path: '/api/auth/logout',
      payload: {
        'refreshToken': refreshToken,
        'refreshSessionId': refreshSessionId,
      },
    );
  }

  Future<AuthSessionModel> _postSession({
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    final json = await _postJson(path: path, payload: payload);
    return AuthSessionModel.fromJson(json);
  }

  Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    final request = await _httpClient.postUrl(Uri.parse('$_baseUrl$path'));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.write(jsonEncode(payload));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final decoded = _tryDecode(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded?['message'] as String? ??
          'Request failed with status ${response.statusCode}.';
      final uiMessage = _resolveUiMessage(decoded) ?? message;
      throw AuthException(message, uiMessage: uiMessage);
    }

    if (decoded == null) {
      throw const AuthException('Backend returned an empty response.');
    }

    return decoded;
  }

  Future<void> _postWithoutResponse({
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    final request = await _httpClient.postUrl(Uri.parse('$_baseUrl$path'));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.write(jsonEncode(payload));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final decoded = _tryDecode(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded?['message'] as String? ??
          'Request failed with status ${response.statusCode}.';
      final uiMessage = _resolveUiMessage(decoded) ?? message;
      throw AuthException(message, uiMessage: uiMessage);
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  String? _resolveUiMessage(Map<String, dynamic>? decoded) {
    final uiMessage = decoded?['uiMessage'] as String?;
    if (uiMessage != null && uiMessage.trim().isNotEmpty) {
      return uiMessage.trim();
    }

    final errors = decoded?['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = '${value.first}'.trim();
          if (first.isNotEmpty) {
            return first;
          }
        }

        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return null;
  }

  String get _baseUrl {
    return AppConfig.apiBaseUrl.trim();
  }
}
