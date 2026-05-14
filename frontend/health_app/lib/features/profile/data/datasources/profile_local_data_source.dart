import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';

class ProfileLocalDataSource {
  ProfileLocalDataSource();

  static const profileStorageKey = 'profile.user_profile';
  static const notificationsEnabledStorageKey = 'profile.notifications_enabled';

  Future<UserProfileModel?> getProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(profileStorageKey);
    final notificationsEnabled = preferences.getBool(
      notificationsEnabledStorageKey,
    );

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final profile = UserProfileModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (notificationsEnabled == null ||
        notificationsEnabled == profile.notificationsEnabled) {
      return profile;
    }

    return UserProfileModel.fromEntity(
      profile.copyWith(notificationsEnabled: notificationsEnabled),
    );
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
  }
}
