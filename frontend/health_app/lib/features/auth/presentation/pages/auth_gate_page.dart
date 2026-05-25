import 'package:flutter/material.dart';

import '../../../../app/presentation/pages/home_shell_page.dart';
import '../../../../core/services/app_session_cleanup_service.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/secure_credentials_data_source.dart';
import '../../data/repositories/backend_auth_repository.dart';
import '../../data/services/oauth_identity_provider.dart';
import '../controllers/auth_controller.dart';
import 'sign_in_page.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(
      repository: BackendAuthRepository(
        localDataSource: AuthLocalDataSource(),
        remoteDataSource: AuthRemoteDataSource(),
        secureCredentialsDataSource: SecureCredentialsDataSource(),
        appSessionCleanupService: AppSessionCleanupService(),
        oauthIdentityProvider: OAuthIdentityProvider(),
      ),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isLoading) {
          return const _AuthSplash();
        }

        if (_controller.isAuthenticated) {
          return HomeShellPage(onSignOut: _controller.signOut);
        }

        return SignInPage(controller: _controller);
      },
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1FBF4), Color(0xFFEAF9F1)],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      ),
    );
  }
}
