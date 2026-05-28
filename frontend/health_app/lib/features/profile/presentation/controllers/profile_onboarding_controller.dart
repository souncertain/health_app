import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileOnboardingStep { welcome, personalInfo, healthInfo }

class ProfileOnboardingController extends ChangeNotifier {
  ProfileOnboardingController({
    required ProfileRepository repository,
    required UserProfile initialProfile,
  }) : _repository = repository,
       _initialProfile = initialProfile;

  static const localizedBloodTypes = <String>[
    'I+',
    'I-',
    'II+',
    'II-',
    'III+',
    'III-',
    'IV+',
    'IV-',
  ];

  final ProfileRepository _repository;
  final UserProfile _initialProfile;

  ProfileOnboardingStep _step = ProfileOnboardingStep.welcome;
  bool _isSaving = false;

  ProfileOnboardingStep get step => _step;
  bool get isSaving => _isSaving;
  UserProfile get initialProfile => _initialProfile;

  void start() {
    if (_step == ProfileOnboardingStep.welcome) {
      _step = ProfileOnboardingStep.personalInfo;
      notifyListeners();
    }
  }

  void nextToHealthInfo() {
    if (_step == ProfileOnboardingStep.personalInfo) {
      _step = ProfileOnboardingStep.healthInfo;
      notifyListeners();
    }
  }

  void goBack() {
    switch (_step) {
      case ProfileOnboardingStep.welcome:
        return;
      case ProfileOnboardingStep.personalInfo:
        _step = ProfileOnboardingStep.welcome;
        notifyListeners();
        return;
      case ProfileOnboardingStep.healthInfo:
        _step = ProfileOnboardingStep.personalInfo;
        notifyListeners();
        return;
    }
  }

  Future<void> complete({
    required String firstName,
    required String lastName,
    required DateTime birthday,
    required ProfileGender gender,
    required String phone,
    int? heightCm,
    double? weightKg,
    String? localizedBloodType,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final normalizedBirthday = DateTime(
        birthday.year,
        birthday.month,
        birthday.day,
      );

      final updatedProfile = _initialProfile.copyWith(
        fullName: _joinFullName(firstName, lastName),
        phone: phone.trim(),
        gender: gender,
        birthDate: normalizedBirthday,
        age: calculateAge(normalizedBirthday),
        bloodType: canonicalBloodTypeFromLocalized(localizedBloodType),
        heightCm: heightCm,
        weightKg: weightKg,
        updatedAt: DateTime.now(),
      );

      await _repository.saveProfile(updatedProfile);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static bool isProfileSetupCompleted(UserProfile profile) {
    final parts = profile.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();

    return parts.length >= 2 &&
        profile.gender != ProfileGender.unspecified &&
        (profile.birthDate != null || profile.age != null);
  }

  static int calculateAge(DateTime birthday) {
    final today = DateTime.now();
    var years = today.year - birthday.year;
    final hadBirthdayThisYear =
        today.month > birthday.month ||
        (today.month == birthday.month && today.day >= birthday.day);
    if (!hadBirthdayThisYear) {
      years--;
    }

    return years.clamp(0, 130);
  }

  static String? canonicalBloodTypeFromLocalized(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return switch (value.trim().toUpperCase()) {
      'I+' => 'O+',
      'I-' => 'O-',
      'II+' => 'A+',
      'II-' => 'A-',
      'III+' => 'B+',
      'III-' => 'B-',
      'IV+' => 'AB+',
      'IV-' => 'AB-',
      'O+' || 'O-' || 'A+' || 'A-' || 'B+' || 'B-' || 'AB+' || 'AB-' =>
        value.trim().toUpperCase(),
      _ => null,
    };
  }

  static String? localizedBloodTypeFromCanonical(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return switch (value.trim().toUpperCase().replaceAll('0', 'O')) {
      'O+' => 'I+',
      'O-' => 'I-',
      'A+' => 'II+',
      'A-' => 'II-',
      'B+' => 'III+',
      'B-' => 'III-',
      'AB+' => 'IV+',
      'AB-' => 'IV-',
      _ => null,
    };
  }

  static String _joinFullName(String firstName, String lastName) {
    return [firstName.trim(), lastName.trim()]
        .where((value) => value.isNotEmpty)
        .join(' ');
  }
}
