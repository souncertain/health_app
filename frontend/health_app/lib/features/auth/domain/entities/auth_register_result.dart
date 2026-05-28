class AuthRegisterResult {
  const AuthRegisterResult({
    required this.email,
    required this.emailConfirmationRequired,
  });

  final String email;
  final bool emailConfirmationRequired;
}
