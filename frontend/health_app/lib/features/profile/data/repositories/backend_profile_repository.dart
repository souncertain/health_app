import '../../../../core/network/api_exception.dart';
import '../../domain/entities/profile_stats_snapshot.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/profile_stats_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

class BackendProfileRepository
    implements ProfileRepository, ProfileStatsRepository {
  BackendProfileRepository({
    required ProfileLocalDataSource localDataSource,
    required ProfileRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final ProfileLocalDataSource _localDataSource;
  final ProfileRemoteDataSource _remoteDataSource;
  ProfileStatsSnapshot? _cachedStats;

  @override
  Future<UserProfile?> getCachedProfile() {
    return _localDataSource.getProfile();
  }

  @override
  Future<UserProfile?> getProfile() async {
    try {
      final page = await _remoteDataSource.getProfilePage();
      _cachedStats = page.stats;
      await _localDataSource.saveProfile(
        UserProfileModel.fromEntity(page.profile),
      );
      return page.profile;
    } on ApiNetworkException {
      return _localDataSource.getProfile();
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final page = await _remoteDataSource.saveProfile(profile);
    _cachedStats = page.stats;
    await _localDataSource.saveProfile(
      UserProfileModel.fromEntity(page.profile),
    );
  }

  @override
  Future<ProfileStatsSnapshot> getProfileStats() async {
    if (_cachedStats != null) {
      return _cachedStats!;
    }

    try {
      final stats = await _remoteDataSource.getProfileStats();
      _cachedStats = stats;
      return stats;
    } on ApiNetworkException {
      return _cachedStats ??
          const ProfileStatsSnapshot(
            bloodPressureReadingsCount: 0,
            medicationsCount: 0,
            appointmentsCount: 0,
            daysTracked: 0,
          );
    }
  }
}
