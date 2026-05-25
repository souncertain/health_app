import '../entities/profile_stats_snapshot.dart';

abstract interface class ProfileStatsRepository {
  Future<ProfileStatsSnapshot> getProfileStats();
}
