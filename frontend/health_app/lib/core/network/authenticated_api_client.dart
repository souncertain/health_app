import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../../features/auth/domain/auth_exception.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/models/auth_session_model.dart';
import 'api_exception.dart';

class AuthenticatedApiClient {
  AuthenticatedApiClient({
    HttpClient? httpClient,
    AuthLocalDataSource? authLocalDataSource,
    AuthRemoteDataSource? authRemoteDataSource,
  }) : _httpClient = httpClient ?? HttpClient(),
       _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSource(),
       _authRemoteDataSource = authRemoteDataSource ?? AuthRemoteDataSource();

  final HttpClient _httpClient;
  final AuthLocalDataSource _authLocalDataSource;
  final AuthRemoteDataSource _authRemoteDataSource;

  Future<dynamic> getJson(String path, {Map<String, String>? queryParameters}) {
    return _sendJson(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> payload,
    Map<String, String>? queryParameters,
  }) {
    return _sendJson(
      method: 'POST',
      path: path,
      queryParameters: queryParameters,
      payload: payload,
    );
  }

  Future<dynamic> putJson(
    String path, {
    required Map<String, dynamic> payload,
    Map<String, String>? queryParameters,
  }) {
    return _sendJson(
      method: 'PUT',
      path: path,
      queryParameters: queryParameters,
      payload: payload,
    );
  }

  Future<dynamic> deleteJson(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _sendJson(
      method: 'DELETE',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> _sendJson({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? payload,
  }) async {
    final session = await _getValidSession();
    final uri = _buildUri(path, queryParameters);

    return _sendAuthorizedJson(
      method: method,
      uri: uri,
      accessToken: session.accessToken,
      payload: payload,
      allowRefreshRetry: true,
    );
  }

  Future<AuthSessionModel> _getValidSession() async {
    final session = await _authLocalDataSource.getSession();
    if (session == null || !session.canEnterApp) {
      throw const ApiUnauthorizedException();
    }

    if (_hasFreshAccessToken(session)) {
      return session;
    }

    return _refreshSession(session);
  }

  Future<AuthSessionModel> _refreshSession(AuthSessionModel session) async {
    final refreshSessionId = session.refreshSessionId?.trim() ?? '';
    final refreshToken = session.refreshToken.trim();
    if (refreshSessionId.isEmpty || refreshToken.isEmpty) {
      await _authLocalDataSource.clearSession();
      throw const ApiUnauthorizedException();
    }

    try {
      final refreshed = await _authRemoteDataSource.refresh(
        refreshToken: refreshToken,
        refreshSessionId: refreshSessionId,
      );
      await _authLocalDataSource.saveSession(refreshed);
      return refreshed;
    } on SocketException {
      throw const ApiNetworkException();
    } on HttpException {
      throw const ApiNetworkException();
    } on HandshakeException {
      throw const ApiNetworkException(
        'Secure connection to the backend failed.',
      );
    } on AuthException {
      await _authLocalDataSource.clearSession();
      throw const ApiUnauthorizedException();
    } catch (_) {
      await _authLocalDataSource.clearSession();
      throw const ApiUnauthorizedException();
    }
  }

  Future<dynamic> _sendAuthorizedJson({
    required String method,
    required Uri uri,
    required String accessToken,
    required Map<String, dynamic>? payload,
    required bool allowRefreshRetry,
  }) async {
    try {
      final request = await _openRequest(method, uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );

      if (payload != null) {
        request.write(jsonEncode(payload));
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = _decodeBody(body);

      if (response.statusCode == 401 && allowRefreshRetry) {
        final currentSession = await _authLocalDataSource.getSession();
        if (currentSession == null) {
          throw const ApiUnauthorizedException();
        }

        final refreshed = await _refreshSession(currentSession);
        return _sendAuthorizedJson(
          method: method,
          uri: uri,
          accessToken: refreshed.accessToken,
          payload: payload,
          allowRefreshRetry: false,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message'] as String?
            : null;
        throw ApiException(
          message ?? 'Request failed with status ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on SocketException {
      throw const ApiNetworkException();
    } on HttpException {
      throw const ApiNetworkException();
    } on HandshakeException {
      throw const ApiNetworkException(
        'Secure connection to the backend failed.',
      );
    }
  }

  Future<HttpClientRequest> _openRequest(String method, Uri uri) {
    switch (method) {
      case 'GET':
        return _httpClient.getUrl(uri);
      case 'POST':
        return _httpClient.postUrl(uri);
      case 'PUT':
        return _httpClient.putUrl(uri);
      case 'DELETE':
        return _httpClient.deleteUrl(uri);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return jsonDecode(trimmed);
  }

  bool _hasFreshAccessToken(AuthSessionModel session) {
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
