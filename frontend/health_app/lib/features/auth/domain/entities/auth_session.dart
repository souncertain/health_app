enum AuthProvider { password, google, yandex }

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.provider,
    required this.accessToken,
    required this.refreshToken,
    required this.issuedAt,
    this.accessTokenExpiresAt,
    this.refreshSessionId,
  });

  final String userId;
  final String displayName;
  final String email;
  final AuthProvider provider;
  final String accessToken;
  final String refreshToken;
  final DateTime issuedAt;
  final DateTime? accessTokenExpiresAt;
  final String? refreshSessionId;

  bool get canEnterApp =>
      accessToken.trim().isNotEmpty || refreshToken.trim().isNotEmpty;

  AuthSession copyWith({
    String? userId,
    String? displayName,
    String? email,
    AuthProvider? provider,
    String? accessToken,
    String? refreshToken,
    DateTime? issuedAt,
    DateTime? accessTokenExpiresAt,
    String? refreshSessionId,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      issuedAt: issuedAt ?? this.issuedAt,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshSessionId: refreshSessionId ?? this.refreshSessionId,
    );
  }
}

extension AuthProviderPresentation on AuthProvider {
  String get label {
    switch (this) {
      case AuthProvider.password:
        return 'Email';
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.yandex:
        return 'Yandex';
    }
  }
}
