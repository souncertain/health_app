import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';

class ProfileLocalDataSource {
  ProfileLocalDataSource();

  static const profileStorageKey = 'profile.user_profile';
  static const notificationsEnabledStorageKey = 'profile.notifications_enabled';
  UserProfileModel? _cachedProfile;
  bool _hasLoadedCache = false;

  Future<UserProfileModel?> getProfile() async {
    if (_hasLoadedCache) {
      return _cachedProfile;
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(profileStorageKey);
    final notificationsEnabled = preferences.getBool(
      notificationsEnabledStorageKey,
    );

    if (raw == null || raw.isEmpty) {
      _cachedProfile = null;
      _hasLoadedCache = true;
      return null;
    }

    final profile = UserProfileModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (notificationsEnabled == null ||
        notificationsEnabled == profile.notificationsEnabled) {
      _cachedProfile = profile;
      _hasLoadedCache = true;
      return profile;
    }

    _cachedProfile = UserProfileModel.fromEntity(
      profile.copyWith(notificationsEnabled: notificationsEnabled),
    );
    _hasLoadedCache = true;
    return _cachedProfile;
  }

  Future<void> saveProfile(UserProfileModel profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      profileStorageKey,
      jsonEncode(profile.toJson()),
    );
    await preferences.setBool(
      notificationsEnabledStorageKey,
      profile.notificationsEnabled,
    );
    _cachedProfile = profile;
    _hasLoadedCache = true;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(profileStorageKey);
    await preferences.remove(notificationsEnabledStorageKey);
    _cachedProfile = null;
    _hasLoadedCache = true;
  }
}
