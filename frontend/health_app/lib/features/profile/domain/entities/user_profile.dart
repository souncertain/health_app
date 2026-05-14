enum ProfileGender { male, female, unspecified }

enum ProfileSyncState { localOnly, pendingUpload, synced }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.age,
    required this.bloodType,
    required this.heightCm,
    required this.weightKg,
    required this.primaryDoctor,
    required this.emergencyContactName,
    required this.emergencyContactDetails,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncState = ProfileSyncState.localOnly,
  });

  static const _unset = Object();

  final String id;
  final String fullName;
  final String email;
  final ProfileGender gender;
  final int? age;
  final String? bloodType;
  final int? heightCm;
  final double? weightKg;
  final String? primaryDoctor;
  final String? emergencyContactName;
  final String? emergencyContactDetails;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final ProfileSyncState syncState;

  factory UserProfile.empty() {
    final now = DateTime.now();
    return UserProfile(
      id: 'profile-local',
      fullName: '',
      email: '',
      gender: ProfileGender.unspecified,
      age: null,
      bloodType: null,
      heightCm: null,
      weightKg: null,
      primaryDoctor: null,
      emergencyContactName: null,
      emergencyContactDetails: null,
      notificationsEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'П';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm == 0) {
      return null;
    }
    final heightMeters = heightCm! / 100;
    return weightKg! / (heightMeters * heightMeters);
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    ProfileGender? gender,
    Object? age = _unset,
    Object? bloodType = _unset,
    Object? heightCm = _unset,
    Object? weightKg = _unset,
    Object? primaryDoctor = _unset,
    Object? emergencyContactName = _unset,
    Object? emergencyContactDetails = _unset,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? remoteId = _unset,
    ProfileSyncState? syncState,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age == _unset ? this.age : age as int?,
      bloodType: bloodType == _unset ? this.bloodType : bloodType as String?,
      heightCm: heightCm == _unset ? this.heightCm : heightCm as int?,
      weightKg: weightKg == _unset ? this.weightKg : weightKg as double?,
      primaryDoctor: primaryDoctor == _unset
          ? this.primaryDoctor
          : primaryDoctor as String?,
      emergencyContactName: emergencyContactName == _unset
          ? this.emergencyContactName
          : emergencyContactName as String?,
      emergencyContactDetails: emergencyContactDetails == _unset
          ? this.emergencyContactDetails
          : emergencyContactDetails as String?,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId == _unset ? this.remoteId : remoteId as String?,
      syncState: syncState ?? this.syncState,
    );
  }
}
