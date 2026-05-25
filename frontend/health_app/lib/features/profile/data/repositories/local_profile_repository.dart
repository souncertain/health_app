import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../models/user_profile_model.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._localDataSource);

  final ProfileLocalDataSource _localDataSource;

  @override
  Future<UserProfile?> getCachedProfile() {
    return _localDataSource.getProfile();
  }

  @override
  Future<UserProfile?> getProfile() {
    return _localDataSource.getProfile();
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    return _localDataSource.saveProfile(UserProfileModel.fromEntity(profile));
  }
}
