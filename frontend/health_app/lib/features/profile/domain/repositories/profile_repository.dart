import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getCachedProfile();

  Future<UserProfile?> getProfile();

  Future<void> saveProfile(UserProfile profile);
}
