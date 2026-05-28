import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.gender,
    required super.birthDate,
    required super.age,
    required super.bloodType,
    required super.heightCm,
    required super.weightKg,
    required super.primaryDoctor,
    required super.emergencyContactName,
    required super.emergencyContactDetails,
    required super.notificationsEnabled,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncState,
  });

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      gender: profile.gender,
      birthDate: profile.birthDate,
      age: profile.age,
      bloodType: profile.bloodType,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      primaryDoctor: profile.primaryDoctor,
      emergencyContactName: profile.emergencyContactName,
      emergencyContactDetails: profile.emergencyContactDetails,
      notificationsEnabled: profile.notificationsEnabled,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      remoteId: profile.remoteId,
      syncState: profile.syncState,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: ProfileGender.values.firstWhere(
        (value) => value.name == json['gender'],
        orElse: () => ProfileGender.unspecified,
      ),
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      age: json['age'] as int?,
      bloodType: json['bloodType'] as String?,
      heightCm: json['heightCm'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      primaryDoctor: json['primaryDoctor'] as String?,
      emergencyContactName:
          json['emergencyContactName'] as String? ??
          json['emergencyContact'] as String?,
      emergencyContactDetails: json['emergencyContactDetails'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      remoteId: json['remoteId'] as String?,
      syncState: ProfileSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => ProfileSyncState.localOnly,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'gender': gender.name,
      'birthDate': birthDate?.toIso8601String(),
      'age': age,
      'bloodType': bloodType,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'primaryDoctor': primaryDoctor,
      'emergencyContactName': emergencyContactName,
      'emergencyContactDetails': emergencyContactDetails,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'remoteId': remoteId,
      'syncState': syncState.name,
    };
  }
}
