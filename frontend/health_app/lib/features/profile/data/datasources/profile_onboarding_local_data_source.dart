import 'package:shared_preferences/shared_preferences.dart';

class ProfileOnboardingLocalDataSource {
  static const dismissedStorageKeyPrefix = 'profile.onboarding.dismissed.';
  static const completedStorageKeyPrefix = 'profile.onboarding.completed.';

  Future<bool> isDismissed(String userKey) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_dismissedStorageKey(userKey)) ?? false;
  }

  Future<void> setDismissed(String userKey, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_dismissedStorageKey(userKey), value);
  }

  Future<bool> isCompleted(String userKey) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_completedStorageKey(userKey)) ?? false;
  }

  Future<void> setCompleted(String userKey, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedStorageKey(userKey), value);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final keysToRemove = preferences
        .getKeys()
        .where(
          (key) =>
              key.startsWith(dismissedStorageKeyPrefix) ||
              key.startsWith(completedStorageKeyPrefix),
        )
        .toList(growable: false);

    for (final key in keysToRemove) {
      await preferences.remove(key);
    }
  }

  static String _dismissedStorageKey(String userKey) {
    return '$dismissedStorageKeyPrefix${_normalizeUserKey(userKey)}';
  }

  static String _completedStorageKey(String userKey) {
    return '$completedStorageKeyPrefix${_normalizeUserKey(userKey)}';
  }

  static String _normalizeUserKey(String userKey) {
    return userKey.trim().toLowerCase();
  }
}
