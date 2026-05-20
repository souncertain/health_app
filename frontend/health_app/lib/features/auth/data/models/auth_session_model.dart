import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.userId,
    required super.displayName,
    required super.email,
    required super.provider,
    required super.accessToken,
    required super.refreshToken,
    required super.issuedAt,
    super.accessTokenExpiresAt,
    super.refreshSessionId,
  });

  factory AuthSessionModel.fromEntity(AuthSession session) {
    return AuthSessionModel(
      userId: session.userId,
      displayName: session.displayName,
      email: session.email,
      provider: session.provider,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      issuedAt: session.issuedAt,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
      refreshSessionId: session.refreshSessionId,
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      provider: AuthProvider.values.firstWhere(
        (value) => value.name == json['provider'],
        orElse: () => AuthProvider.password,
      ),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      accessTokenExpiresAt: json['accessTokenExpiresAt'] == null
          ? null
          : DateTime.parse(json['accessTokenExpiresAt'] as String),
      refreshSessionId: json['refreshSessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'provider': provider.name,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'issuedAt': issuedAt.toIso8601String(),
      'accessTokenExpiresAt': accessTokenExpiresAt?.toIso8601String(),
      'refreshSessionId': refreshSessionId,
    };
  }
}
