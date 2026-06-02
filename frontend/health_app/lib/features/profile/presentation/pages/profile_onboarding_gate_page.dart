import 'package:flutter/material.dart';

import '../../../../app/presentation/pages/home_shell_page.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/profile_local_data_source.dart';
import '../../data/datasources/profile_onboarding_local_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/backend_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_onboarding_controller.dart';
import 'profile_onboarding_page.dart';

class ProfileOnboardingGatePage extends StatefulWidget {
  const ProfileOnboardingGatePage({
    super.key,
    required this.session,
    required this.onSignOut,
    this.repository,
    this.onboardingLocalDataSource,
  });

  final AuthSession session;
  final Future<void> Function() onSignOut;
  final ProfileRepository? repository;
  final ProfileOnboardingLocalDataSource? onboardingLocalDataSource;

  @override
  State<ProfileOnboardingGatePage> createState() =>
      _ProfileOnboardingGatePageState();
}

class _ProfileOnboardingGatePageState extends State<ProfileOnboardingGatePage> {
  late final ProfileRepository _repository =
      widget.repository ??
      BackendProfileRepository(
        localDataSource: ProfileLocalDataSource(),
        remoteDataSource: ProfileRemoteDataSource(),
      );
  late final ProfileOnboardingLocalDataSource _onboardingLocalDataSource =
      widget.onboardingLocalDataSource ?? ProfileOnboardingLocalDataSource();

  bool _isLoading = true;
  bool _shouldShowOnboarding = false;
  late UserProfile _initialProfile;
  late final String _userKey = _resolveUserKey(widget.session);

  @override
  void initState() {
    super.initState();
    _initialProfile = _seedProfile(UserProfile.empty());
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final dismissed = await _onboardingLocalDataSource.isDismissed(_userKey);
      final completed = await _onboardingLocalDataSource.isCompleted(_userKey);
      final cachedProfile = await _repository.getCachedProfile();
      final initialProfile = _seedProfile(cachedProfile ?? UserProfile.empty());

      if (mounted) {
        setState(() {
          _initialProfile = initialProfile;
          _shouldShowOnboarding =
              !dismissed &&
              !completed &&
              !ProfileOnboardingController.isProfileSetupCompleted(
                initialProfile,
              );
        });
      }

      final remoteProfile = await _repository.getProfile();
      final effectiveProfile = _seedProfile(remoteProfile ?? initialProfile);

      if (!mounted) {
        return;
      }

      setState(() {
        _initialProfile = effectiveProfile;
        _shouldShowOnboarding =
            !dismissed &&
            !completed &&
            !ProfileOnboardingController.isProfileSetupCompleted(
              effectiveProfile,
            );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipOnboarding() async {
    await _onboardingLocalDataSource.setDismissed(_userKey, true);
    await _onboardingLocalDataSource.setCompleted(_userKey, false);
    if (!mounted) {
      return;
    }

    setState(() => _shouldShowOnboarding = false);
  }

  Future<void> _completeOnboarding() async {
    await _onboardingLocalDataSource.setDismissed(_userKey, false);
    await _onboardingLocalDataSource.setCompleted(_userKey, true);
    if (!mounted) {
      return;
    }

    setState(() => _shouldShowOnboarding = false);
  }

  UserProfile _seedProfile(UserProfile profile) {
    final email = profile.email.trim().isEmpty
        ? widget.session.email.trim()
        : profile.email.trim();
    final fullName = profile.fullName.trim().isEmpty
        ? widget.session.displayName.trim()
        : profile.fullName.trim();

    return profile.copyWith(
      email: email,
      fullName: fullName,
      remoteId:
          (profile.remoteId?.trim().isNotEmpty ?? false)
              ? profile.remoteId
              : widget.session.userId,
    );
  }

  static String _resolveUserKey(AuthSession session) {
    final userId = session.userId.trim();
    if (userId.isNotEmpty) {
      return userId;
    }

    final email = session.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return 'anonymous-user';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2FBF3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }

    if (_shouldShowOnboarding) {
      return ProfileOnboardingPage(
        initialProfile: _initialProfile,
        repository: _repository,
        onSkipped: _skipOnboarding,
        onCompleted: _completeOnboarding,
      );
    }

    return HomeShellPage(onSignOut: widget.onSignOut);
  }
}
