import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
import '../../domain/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../controllers/auth_controller.dart';
import '../widgets/email_confirmation_sheet.dart';
import '../widgets/forgot_password_sheet.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.controller.savedCredentials.email,
  );
  late final _passwordController = TextEditingController(
    text: widget.controller.savedCredentials.password,
  );

  bool _passwordVisible = false;

  @override
  void didUpdateWidget(covariant SignInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_emailController.text.isEmpty &&
        widget.controller.savedCredentials.email.isNotEmpty) {
      _emailController.text = widget.controller.savedCredentials.email;
    }
    if (_passwordController.text.isEmpty &&
        widget.controller.savedCredentials.password.isNotEmpty) {
      _passwordController.text = widget.controller.savedCredentials.password;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await widget.controller.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      _showError(error, 'Не удалось авторизоваться. Попробуйте позже.');
    } catch (_) {
      _showMessage('Не удалось авторизоваться. Попробуйте позже.');
    }
  }

  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final result = await widget.controller.registerWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }

      _showMessage(
        'На вашу электронную почту отправлен код подтверждения. Введите его, чтобы завершить регистрацию.',
      );
      await showEmailConfirmationSheet(
        context,
        controller: widget.controller,
        email: result.email,
      );
    } on AuthException catch (error) {
      _showError(error,'Не удалось создать аккаунт. Попробуйте ещё раз.');
    } catch (_) {
      _showMessage('Не удалось создать аккаунт. Попробуйте ещё раз.');
    }
  }

  Future<void> _submitProviderSignIn(AuthProvider provider) async {
    try {
      await widget.controller.signInWithProvider(provider);
    } on AuthException catch (error) {
      final providerName = switch (provider) {
        AuthProvider.google => 'Google',
        AuthProvider.yandex => 'Yandex',
        AuthProvider.password => 'Email',
      };
      _showError(error, 'Не удалось войти с помощью $providerName. Попробуйте ещё раз.');
    } catch (_) {
      final providerName = switch (provider) {
        AuthProvider.google => 'Google',
        AuthProvider.yandex => 'Yandex',
        AuthProvider.password => 'Email',
      };
      _showMessage('Не удалось войти с помощью $providerName. Попробуйте ещё раз.');
    }
  }

  Future<void> _openForgotPasswordFlow() async {
    final restoredEmail = await showForgotPasswordSheet(
      context,
      controller: widget.controller,
      initialEmail: _emailController.text.trim(),
    );

    if (!mounted || restoredEmail == null) {
      return;
    }

    _emailController.text = restoredEmail;
    _passwordController.clear();
    _showMessage('Ваш пароль обновлён. Теперь вы можете войти с новым паролем..');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2FBF3), Color(0xFFEAF9EF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: 40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFB7F6CC).withValues(alpha: 0.75),
                      Color(0xFFB7F6CC).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x291DB954),
                              blurRadius: 28,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'HealthTrack',
                        style: TextStyle(
                          color: Color(0xFF176A37),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionDivider(label: 'EMAIL AND PASSWORD'),
                      const SizedBox(height: 22),
                      const _FieldLabel(label: 'Email'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        style: const TextStyle(
                          color: Color(0xFF17492C),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Почта',
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFF7BE39E),
                          ),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Введите адрес электронной почты';
                          }
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(trimmed)) {
                            return 'Неверный формат электронной почты';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel(label: 'Password'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(
                          color: Color(0xFF17492C),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Пароль',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF7BE39E),
                          ),
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
                              color: const Color(0xFF7BE39E),
                            ),
                          ),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Введите пароль';
                          }
                          final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$');
                          if (!passwordRegex.hasMatch(trimmed)) {
                            return 'Пароль должен содержать не меньше 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : _openForgotPasswordFlow,
                          child: const Text(
                            'Забыли пароль?',
                            style: TextStyle(
                              color: Color(0xFF1AA84D),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : _submitSignIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                            disabledBackgroundColor: const Color(
                              0xFF1DB954,
                            ).withValues(alpha: 0.55),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 12,
                            shadowColor: const Color(
                              0xFF1DB954,
                            ).withValues(alpha: 0.3),
                          ),
                          child: widget.controller.isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Войти',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : _submitRegister,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF176A37),
                            side: const BorderSide(
                              color: Color(0xFF1DB954),
                              width: 1.6,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.86,
                            ),
                          ),
                          child: const Text(
                            'Создать аккаунт',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SocialButton(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF176A37),
                        icon: const _BrandBadge(
                          backgroundColor: Color(0xFFEFF4FF),
                          foregroundColor: Color(0xFF4285F4),
                          label: 'G',
                        ),
                        label: 'Войти с помощью Google',
                        onTap: widget.controller.isSubmitting
                            ? null
                            : () => _submitProviderSignIn(AuthProvider.google),
                      ),
                      const SizedBox(height: 14),
                      _SocialButton(
                        backgroundColor: const Color(0xFFFFF2F2),
                        foregroundColor: const Color(0xFF8D1313),
                        icon: const _BrandBadge(
                          backgroundColor: Color(0xFFFFE1E1),
                          foregroundColor: Color(0xFFFF0000),
                          label: 'Y',
                        ),
                        label: 'Войти с помощью Yandex',
                        onTap: widget.controller.isSubmitting
                            ? null
                            : () => _submitProviderSignIn(AuthProvider.yandex),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF95C6A6),
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFDDF0E2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF176A37),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD6EEDD), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF79C78F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD6EEDD), thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDF0E2), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120C1C46),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
