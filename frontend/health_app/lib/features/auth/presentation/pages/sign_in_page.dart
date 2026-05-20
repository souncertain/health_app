import 'package:flutter/material.dart';

import '../../domain/auth_exception.dart';
import '../controllers/auth_controller.dart';

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
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not sign in. Please try again.');
    }
  }

  Future<void> _submitRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await widget.controller.registerWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not create the account. Please try again.');
    }
  }

  void _showProviderUnavailable() {
    _showMessage(
      'Google and Yandex sign-in will be connected next. For now, use email and password.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in or create an account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4F8A63),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The app now uses backend authentication and restores the session on the next launch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4F8A63),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFD7F2DF),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120C1C46),
                              blurRadius: 22,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lock_clock_outlined,
                              color: Color(0xFF1DB954),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Use the same email and password form for both actions: Sign in checks an existing account, and Create account immediately sends registration to the backend.',
                                style: TextStyle(
                                  color: Color(0xFF176A37),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
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
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFF7BE39E),
                          ),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Enter your email';
                          }
                          if (!trimmed.contains('@')) {
                            return 'Enter a valid email';
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
                          hintText: 'Enter your password',
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
                            return 'Enter your password';
                          }
                          if (trimmed.length < 6) {
                            return 'Minimum 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showMessage(
                            'Password recovery will be connected after the auth flow is fully integrated.',
                          ),
                          child: const Text(
                            'Forgot password?',
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
                                  'Sign in',
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
                            'Create account',
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
                        label: 'Continue with Google',
                        onTap: widget.controller.isSubmitting
                            ? null
                            : _showProviderUnavailable,
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
                        label: 'Continue with Yandex',
                        onTap: widget.controller.isSubmitting
                            ? null
                            : _showProviderUnavailable,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'By continuing, you agree to the terms of use and the privacy policy of the service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8DB49A),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
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
