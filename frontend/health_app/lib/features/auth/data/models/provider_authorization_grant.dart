import '../../domain/entities/auth_session.dart';

class ProviderAuthorizationGrant {
  const ProviderAuthorizationGrant({
    required this.provider,
    this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
  });

  final AuthProvider provider;
  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
}
