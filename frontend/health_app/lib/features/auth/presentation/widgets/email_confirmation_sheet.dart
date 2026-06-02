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
      _showError(
        error,
        'Не удалось подтвердить почту. Попробуйте ещё раз.',
      );
    } catch (_) {
      _showMessage('Не удалось подтвердить почту. Попробуйте ещё раз.');
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

      _showMessage('Новый код подтверждения уже отправлен на вашу почту.');
    } on AuthException catch (error) {
      _showError(error, 'Не удалось отправить код повторно.');
    } catch (_) {
      _showMessage('Не удалось отправить код повторно.');
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
      title: 'Подтвердите почту',
      busy: widget.controller.isSubmitting,
      subtitle: const Text(
        'Мы отправили одноразовый код на указанную почту. Введите его ниже, чтобы завершить регистрацию и войти в приложение.',
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
              label: 'Электронная почта',
              hintText: 'Почта, указанная при регистрации',
              controller: _emailController,
              accentColor: accentColor,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Код подтверждения',
              hintText: 'Введите код из письма',
              controller: _codeController,
              accentColor: accentColor,
              keyboardType: TextInputType.number,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Введите код подтверждения';
                }
                if (trimmed.length < 4) {
                  return 'Код слишком короткий';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppBusyFilledButton(
                busy: widget.controller.isSubmitting,
                label: 'Подтвердить почту',
                color: accentColor,
                onPressed: _confirmEmail,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: AppBusyOutlinedButton(
                busy: widget.controller.isSubmitting,
                label: 'Отправить код повторно',
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
