import 'package:flutter/material.dart';

import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/auth_exception.dart';
import '../controllers/auth_controller.dart';

Future<String?> showForgotPasswordSheet(
  BuildContext context, {
  required AuthController controller,
  required String initialEmail,
}) {
  return showAppModalSheet<String>(
    context: context,
    heightFactor: 0.92,
    builder: (_) => ForgotPasswordSheet(
      controller: controller,
      initialEmail: initialEmail,
    ),
  );
}

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({
    super.key,
    required this.controller,
    required this.initialEmail,
  });

  final AuthController controller;
  final String initialEmail;

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  late final _emailController = TextEditingController(text: widget.initialEmail);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeRequested = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await widget.controller.requestPasswordReset(
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _codeRequested = true;
      });
      _showMessage(
        'If an account exists for this email, we sent a reset code to the mailbox.',
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not send the reset code. Please try again.');
    }
  }

  Future<void> _resetPassword() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await widget.controller.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(_emailController.text.trim());
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not reset the password. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF1DB954);

    return AppFormSheet(
      title: 'Forgot password',
      busy: widget.controller.isSubmitting,
      subtitle: const Text(
        'We use a one-time code sent to your email. The code expires quickly and can only be used once.',
        style: TextStyle(
          color: Color(0xFF61738F),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _requestFormKey,
            child: AppTextField(
              label: 'Email',
              hintText: 'Enter your account email',
              controller: _emailController,
              accentColor: accentColor,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppBusyOutlinedButton(
              busy: widget.controller.isSubmitting,
              label: _codeRequested ? 'Send code again' : 'Send reset code',
              color: accentColor,
              onPressed: _requestCode,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: !_codeRequested
                ? const _WaitingForCodeHint(key: ValueKey('request-hint'))
                : Form(
                    key: _resetFormKey,
                    child: Column(
                      key: const ValueKey('reset-form'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: Color(0xFFD7E3F3)),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Reset code',
                          hintText: 'Enter the code from the email',
                          controller: _codeController,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Enter the code from the email';
                            }
                            if (trimmed.length < 4) {
                              return 'The code looks too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'New password',
                          hintText: 'Create a new password',
                          controller: _passwordController,
                          accentColor: accentColor,
                          obscureText: !_passwordVisible,
                          validator: _passwordValidator,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8FA1BC),
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF12203F),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF8FA1BC),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Confirm password',
                          hintText: 'Repeat the new password',
                          controller: _confirmPasswordController,
                          accentColor: accentColor,
                          obscureText: !_confirmPasswordVisible,
                          validator: (value) {
                            final baseError = _passwordValidator(value);
                            if (baseError != null) {
                              return baseError;
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8FA1BC),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: AppBusyFilledButton(
                            busy: widget.controller.isSubmitting,
                            label: 'Update password',
                            color: accentColor,
                            onPressed: _resetPassword,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your email';
    }
    if (!trimmed.contains('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter the new password';
    }
    if (trimmed.length < 6) {
      return 'Minimum 6 characters';
    }
    return null;
  }
}

class _WaitingForCodeHint extends StatelessWidget {
  const _WaitingForCodeHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FCFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E3F3), width: 1.4),
      ),
      child: const Text(
        'After the code arrives, enter it here together with your new password. We always return the same response for unknown emails to avoid leaking account existence.',
        style: TextStyle(
          color: Color(0xFF61738F),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
    );
  }
}
