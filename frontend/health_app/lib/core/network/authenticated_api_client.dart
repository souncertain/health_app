import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/models/auth_session_model.dart';
import '../../features/auth/domain/auth_exception.dart';
import 'api_exception.dart';

class ApiMultipartFile {
  const ApiMultipartFile({
    required this.fieldName,
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fieldName;
  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

class AuthenticatedApiClient {
  static final HttpClient _sharedHttpClient = HttpClient()
    ..idleTimeout = const Duration(minutes: 2)
    ..connectionTimeout = const Duration(seconds: 10)
    ..maxConnectionsPerHost = 8;

  AuthenticatedApiClient({
    HttpClient? httpClient,
    AuthLocalDataSource? authLocalDataSource,
    AuthRemoteDataSource? authRemoteDataSource,
  }) : _httpClient = httpClient ?? _sharedHttpClient,
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

  Future<dynamic> postMultipart(
    String path, {
    required List<ApiMultipartFile> files,
    Map<String, String>? fields,
    Map<String, String>? queryParameters,
  }) async {
    final session = await _getValidSession();
    final uri = _buildUri(path, queryParameters);

    return _sendAuthorizedMultipart(
      uri: uri,
      accessToken: session.accessToken,
      files: files,
      fields: fields ?? const {},
      allowRefreshRetry: true,
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
      return _handleResponse(
        response,
        allowRefreshRetry: allowRefreshRetry,
        retry: (refreshedToken) => _sendAuthorizedJson(
          method: method,
          uri: uri,
          accessToken: refreshedToken,
          payload: payload,
          allowRefreshRetry: false,
        ),
      );
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

  Future<dynamic> _sendAuthorizedMultipart({
    required Uri uri,
    required String accessToken,
    required List<ApiMultipartFile> files,
    required Map<String, String> fields,
    required bool allowRefreshRetry,
  }) async {
    try {
      final request = await _httpClient.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );

      final boundary =
          '----healthapp-boundary-${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      final body = _buildMultipartBody(
        boundary: boundary,
        files: files,
        fields: fields,
      );
      request.add(body);

      final response = await request.close();
      return _handleResponse(
        response,
        allowRefreshRetry: allowRefreshRetry,
        retry: (refreshedToken) => _sendAuthorizedMultipart(
          uri: uri,
          accessToken: refreshedToken,
          files: files,
          fields: fields,
          allowRefreshRetry: false,
        ),
      );
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

  Future<dynamic> _handleResponse(
    HttpClientResponse response, {
    required bool allowRefreshRetry,
    required Future<dynamic> Function(String refreshedToken) retry,
  }) async {
    final body = await response.transform(utf8.decoder).join();
    final decoded = _decodeBody(body);

    if (response.statusCode == 401 && allowRefreshRetry) {
      final currentSession = await _authLocalDataSource.getSession();
      if (currentSession == null) {
        throw const ApiUnauthorizedException();
      }

      final refreshed = await _refreshSession(currentSession);
      return retry(refreshed.accessToken);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payloadMap = decoded is Map<String, dynamic> ? decoded : null;
      final message = payloadMap?['message'] as String?;
      final uiMessage = _extractUiMessage(payloadMap);
      final fieldErrors = _parseFieldErrors(payloadMap?['errors']);

      if ((uiMessage?.isNotEmpty ?? false) || fieldErrors.isNotEmpty) {
        throw ApiValidationException(
          message ?? 'Validation failed.',
          uiMessage:
              uiMessage ??
              _firstFieldError(fieldErrors) ??
              message ??
              'Validation failed.',
          fieldErrors: fieldErrors,
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        message ?? 'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
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

  Uint8List _buildMultipartBody({
    required String boundary,
    required List<ApiMultipartFile> files,
    required Map<String, String> fields,
  }) {
    final builder = BytesBuilder(copy: false);
    final boundaryLine = '--$boundary\r\n';

    for (final entry in fields.entries) {
      builder.add(utf8.encode(boundaryLine));
      builder.add(
        utf8.encode(
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n',
        ),
      );
      builder.add(utf8.encode(entry.value));
      builder.add(utf8.encode('\r\n'));
    }

    for (final file in files) {
      builder.add(utf8.encode(boundaryLine));
      builder.add(
        utf8.encode(
          'Content-Disposition: form-data; name="${file.fieldName}"; filename="${file.fileName}"\r\n',
        ),
      );
      builder.add(utf8.encode('Content-Type: ${file.contentType}\r\n\r\n'));
      builder.add(file.bytes);
      builder.add(utf8.encode('\r\n'));
    }

    builder.add(utf8.encode('--$boundary--\r\n'));
    return builder.takeBytes();
  }

  Map<String, List<String>> _parseFieldErrors(dynamic rawErrors) {
    if (rawErrors is! Map) {
      return const {};
    }

    final result = <String, List<String>>{};
    for (final entry in rawErrors.entries) {
      final key = '${entry.key}';
      final value = entry.value;
      if (value is List) {
        result[key] = value.map((item) => '$item').toList();
        continue;
      }

      if (value is String) {
        result[key] = [value];
      }
    }

    return result;
  }

  String? _firstFieldError(Map<String, List<String>> fieldErrors) {
    for (final errors in fieldErrors.values) {
      for (final error in errors) {
        final trimmed = error.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  String? _extractUiMessage(Map<String, dynamic>? payload) {
    final value = payload?['uiMessage'];
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return null;
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
