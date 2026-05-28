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
  });

  final AuthSession session;
  final Future<void> Function() onSignOut;
  final ProfileRepository? repository;

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
  final _onboardingLocalDataSource = ProfileOnboardingLocalDataSource();

  bool _isLoading = true;
  bool _shouldShowOnboarding = false;
  late UserProfile _initialProfile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dismissed = await _onboardingLocalDataSource.isDismissed();
    final profile =
        await _repository.getProfile() ??
        await _repository.getCachedProfile() ??
        UserProfile.empty();
    final seededProfile = _seedProfile(profile);

    if (!mounted) {
      return;
    }

    setState(() {
      _initialProfile = seededProfile;
      _shouldShowOnboarding =
          !dismissed &&
          !ProfileOnboardingController.isProfileSetupCompleted(seededProfile);
      _isLoading = false;
    });
  }

  UserProfile _seedProfile(UserProfile profile) {
    final now = DateTime.now();
    final hasDisplayName =
        widget.session.displayName.trim().isNotEmpty &&
        widget.session.displayName.trim().toLowerCase() != 'user';

    return profile.copyWith(
      fullName: profile.fullName.trim().isNotEmpty
          ? profile.fullName
          : (hasDisplayName ? widget.session.displayName.trim() : profile.fullName),
      email: profile.email.trim().isNotEmpty
          ? profile.email
          : widget.session.email.trim(),
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt == UserProfile.empty().updatedAt
          ? now
          : profile.updatedAt,
    );
  }

  Future<void> _handleSkipped() async {
    await _onboardingLocalDataSource.setDismissed(true);
    if (!mounted) {
      return;
    }

    setState(() => _shouldShowOnboarding = false);
  }

  Future<void> _handleCompleted() async {
    await _onboardingLocalDataSource.setDismissed(false);
    if (!mounted) {
      return;
    }

    setState(() => _shouldShowOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_shouldShowOnboarding) {
      return ProfileOnboardingPage(
        initialProfile: _initialProfile,
        repository: _repository,
        onSkipped: _handleSkipped,
        onCompleted: _handleCompleted,
      );
    }

    return HomeShellPage(onSignOut: widget.onSignOut);
  }
}
