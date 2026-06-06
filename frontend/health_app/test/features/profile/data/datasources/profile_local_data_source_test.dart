import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:health_app/features/profile/data/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/test_data.dart';

void main() {
  late ProfileLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = ProfileLocalDataSource();
  });

  test('getProfile returns null when no cached profile exists', () async {
    expect(await dataSource.getProfile(), isNull);
  });

  test('saveProfile persists and restores profile', () async {
    final profile = UserProfileModel.fromEntity(
      sampleUserProfile(fullName: 'Test User'),
    );

    await dataSource.saveProfile(profile);

    final restored = await dataSource.getProfile();
    expect(restored?.fullName, 'Test User');
    expect(restored?.notificationsEnabled, isTrue);
  });

  test('watchProfileChanges emits updates after save and clear', () async {
    final profile = UserProfileModel.fromEntity(
      sampleUserProfile(fullName: 'Updated User'),
    );
    final events = <UserProfileModel?>[];
    final subscription = dataSource.watchProfileChanges().listen(events.add);

    await dataSource.saveProfile(profile);
    await Future<void>.delayed(Duration.zero);
    await dataSource.clear();
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();

    expect(events, hasLength(2));
    expect(events.first?.fullName, 'Updated User');
    expect(events.last, isNull);
  });

  test(
    'getProfile prefers standalone notifications flag when it differs',
    () async {
      final profile = UserProfileModel.fromEntity(
        sampleUserProfile(notificationsEnabled: false),
      );
      final payload = jsonEncode(profile.toJson());
      SharedPreferences.setMockInitialValues({
        ProfileLocalDataSource.profileStorageKey: payload,
        ProfileLocalDataSource.notificationsEnabledStorageKey: true,
      });
      dataSource = ProfileLocalDataSource();

      final restored = await dataSource.getProfile();

      expect(restored?.notificationsEnabled, isTrue);
    },
  );

  test('clear removes profile and notifications flag', () async {
    await dataSource.saveProfile(
      UserProfileModel.fromEntity(sampleUserProfile()),
    );

    await dataSource.clear();

    expect(await dataSource.getProfile(), isNull);
  });
}
