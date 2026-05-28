import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/auth_exception.dart';
import '../controllers/auth_controller.dart';

Future<void> showEmailConfirmationSheet(
  BuildContext context, {
  required AuthController controller,
  required String email,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.9,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => EmailConfirmationSheet(controller: controller, email: email),
  );
}

class EmailConfirmationSheet extends StatefulWidget {
  const EmailConfirmationSheet({
    super.key,
    required this.controller,
    required this.email,
  });

  final AuthController controller;
  final String email;

  @override
  State<EmailConfirmationSheet> createState() => _EmailConfirmationSheetState();
}

class _EmailConfirmationSheetState extends State<EmailConfirmationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.email,
  );
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirmEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await widget.controller.confirmEmail(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on AuthException catch (error) {
      _showError(error, 'Could not confirm the email. Please try again.');
    } catch (_) {
      _showMessage('Could not confirm the email. Please try again.');
    }
  }

  Future<void> _resendCode() async {
    try {
      await widget.controller.resendEmailConfirmation(
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      _showMessage('We sent a new confirmation code to the email address.');
    } on AuthException catch (error) {
      _showError(error, 'Could not resend the confirmation code.');
    } catch (_) {
      _showMessage('Could not resend the confirmation code.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error, String fallbackMessage) {
    showAppErrorSnackBarForException(
      context,
      error,
      fallbackMessage: fallbackMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF1DB954);

    return AppFormSheet(
      title: 'Confirm your email',
      busy: widget.controller.isSubmitting,
      subtitle: const Text(
        'We sent a one-time confirmation code to your email. Enter it below to finish creating the account and open the app.',
        style: TextStyle(
          color: Color(0xFF61738F),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Email',
              hintText: 'Your registration email',
              controller: _emailController,
              accentColor: accentColor,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Confirmation code',
              hintText: 'Enter the code from the email',
              controller: _codeController,
              accentColor: accentColor,
              keyboardType: TextInputType.number,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Enter the confirmation code';
                }
                if (trimmed.length < 4) {
                  return 'The code looks too short';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppBusyFilledButton(
                busy: widget.controller.isSubmitting,
                label: 'Confirm email',
                color: accentColor,
                onPressed: _confirmEmail,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: AppBusyOutlinedButton(
                busy: widget.controller.isSubmitting,
                label: 'Send code again',
                color: accentColor,
                onPressed: _resendCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
