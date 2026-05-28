import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';

import '../../../../support/test_data.dart';

void main() {
  test('empty factory provides sensible defaults', () {
    final profile = UserProfile.empty();

    expect(profile.id, 'profile-local');
    expect(profile.fullName, isEmpty);
    expect(profile.notificationsEnabled, isTrue);
  });

  test('initials returns fallback when fullName is empty', () {
    final profile = sampleUserProfile(fullName: '');

    expect(profile.initials, isNotEmpty);
  });

  test('initials returns first letter for a single name', () {
    final profile = sampleUserProfile(fullName: 'Ivan');

    expect(profile.initials, 'I');
  });

  test('initials returns first and last initials for multiple names', () {
    final profile = sampleUserProfile(fullName: 'Ivan Sergeevich Petrov');

    expect(profile.initials, 'IP');
  });

  test('bmi returns null when required values are missing', () {
    final profile = sampleUserProfile(heightCm: null);

    expect(profile.bmi, isNull);
  });

  test('bmi returns null when height is zero', () {
    final profile = sampleUserProfile(heightCm: 0);

    expect(profile.bmi, isNull);
  });

  test('bmi is calculated from weight and height', () {
    final profile = sampleUserProfile(heightCm: 180, weightKg: 81);

    expect(profile.bmi, closeTo(25, 0.1));
  });

  test('copyWith can clear nullable values using explicit null', () {
    final profile = sampleUserProfile(
      primaryDoctor: 'Doctor',
      emergencyContactName: 'Anna',
    );

    final updated = profile.copyWith(
      primaryDoctor: null,
      emergencyContactName: null,
    );

    expect(updated.primaryDoctor, isNull);
    expect(updated.emergencyContactName, isNull);
  });
}
