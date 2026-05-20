class SavedCredentials {
  const SavedCredentials({required this.email, required this.password});

  const SavedCredentials.empty() : email = '', password = '';

  final String email;
  final String password;

  bool get hasData => email.isNotEmpty || password.isNotEmpty;
}
