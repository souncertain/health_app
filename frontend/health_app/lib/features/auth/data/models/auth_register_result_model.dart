import '../../domain/entities/auth_register_result.dart';

class AuthRegisterResultModel extends AuthRegisterResult {
  const AuthRegisterResultModel({
    required super.email,
    required super.emailConfirmationRequired,
  });

  factory AuthRegisterResultModel.fromJson(Map<String, dynamic> json) {
    return AuthRegisterResultModel(
      email: json['email'] as String? ?? '',
      emailConfirmationRequired:
          json['emailConfirmationRequired'] as bool? ?? true,
    );
  }
}
