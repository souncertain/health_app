class AuthException implements Exception {
  const AuthException(this.message, {String? uiMessage})
    : uiMessage = uiMessage ?? message;

  final String message;
  final String uiMessage;

  @override
  String toString() => uiMessage;
}
