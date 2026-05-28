import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/profile_stats_snapshot.dart';
import '../../domain/entities/user_profile.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource({AuthenticatedApiClient? apiClient})
    : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<ProfilePageRemoteModel> getProfilePage() async {
    final json = await _apiClient.getJson('/api/profile/me');
    return _pageFromJson(json as Map<String, dynamic>);
  }

  Future<ProfileStatsSnapshot> getProfileStats() async {
    final json = await _apiClient.getJson('/api/profile/me/stats');
    return _statsFromJson(json as Map<String, dynamic>);
  }

  Future<ProfilePageRemoteModel> saveProfile(UserProfile profile) async {
    final json = await _apiClient.putJson(
      '/api/profile/me',
      payload: {
        'fullName': profile.fullName,
        'email': profile.email,
        'phone': profile.phone,
        'gender': _genderToBackend(profile.gender),
        'birthday': profile.birthDate?.toUtc().toIso8601String(),
        'age': profile.age,
        'bloodType': profile.bloodType,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'primaryDoctor': profile.primaryDoctor,
        'emergencyContactName': profile.emergencyContactName,
        'emergencyContactDetails': profile.emergencyContactDetails,
        'notificationsEnabled': profile.notificationsEnabled,
      },
    );

    return _pageFromJson(json as Map<String, dynamic>);
  }

  ProfilePageRemoteModel _pageFromJson(Map<String, dynamic> json) {
    final rawRemoteId = json['id'] as String? ?? '';
    final remoteId = rawRemoteId == _emptyGuid ? null : rawRemoteId;
    return ProfilePageRemoteModel(
      profile: UserProfile(
        id: remoteId ?? 'profile-me',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        gender: _genderFromBackend(json['gender'] as String?),
        birthDate: json['birthday'] == null
            ? null
            : DateTime.parse(json['birthday'] as String).toLocal(),
        age: json['age'] as int?,
        bloodType: json['bloodType'] as String?,
        heightCm: (json['heightCm'] as num?)?.toInt(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        primaryDoctor: json['primaryDoctor'] as String?,
        emergencyContactName: json['emergencyContactName'] as String?,
        emergencyContactDetails: json['emergencyContactDetails'] as String?,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        remoteId: remoteId,
        syncState: ProfileSyncState.synced,
      ),
      stats: _statsFromJson(json['stats'] as Map<String, dynamic>? ?? const {}),
    );
  }

  ProfileStatsSnapshot _statsFromJson(Map<String, dynamic> json) {
    return ProfileStatsSnapshot(
      bloodPressureReadingsCount:
          (json['bloodPressureReadingsCount'] as num?)?.toInt() ?? 0,
      medicationsCount: (json['medicationsCount'] as num?)?.toInt() ?? 0,
      appointmentsCount: (json['appointmentsCount'] as num?)?.toInt() ?? 0,
      daysTracked: (json['daysTracked'] as num?)?.toInt() ?? 0,
    );
  }

  ProfileGender _genderFromBackend(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'male':
        return ProfileGender.male;
      case 'female':
        return ProfileGender.female;
      default:
        return ProfileGender.unspecified;
    }
  }

  String _genderToBackend(ProfileGender gender) {
    switch (gender) {
      case ProfileGender.male:
        return 'male';
      case ProfileGender.female:
        return 'female';
      case ProfileGender.unspecified:
        return 'unspecified';
    }
  }

  static const _emptyGuid = '00000000-0000-0000-0000-000000000000';
}

class ProfilePageRemoteModel {
  const ProfilePageRemoteModel({required this.profile, required this.stats});

  final UserProfile profile;
  final ProfileStatsSnapshot stats;
}
