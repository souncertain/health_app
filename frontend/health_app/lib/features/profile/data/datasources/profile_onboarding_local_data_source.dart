import 'package:shared_preferences/shared_preferences.dart';

class ProfileOnboardingLocalDataSource {
  static const dismissedStorageKey = 'profile.onboarding.dismissed';

  Future<bool> isDismissed() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(dismissedStorageKey) ?? false;
  }

  Future<void> setDismissed(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(dismissedStorageKey, value);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(dismissedStorageKey);
  }
}
