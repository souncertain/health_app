import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/data/datasources/profile_onboarding_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProfileOnboardingLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = ProfileOnboardingLocalDataSource();
  });

  test('stores dismissed state separately for each user', () async {
    await dataSource.setDismissed('user-a', true);
    await dataSource.setDismissed('user-b', false);

    expect(await dataSource.isDismissed('user-a'), isTrue);
    expect(await dataSource.isDismissed('user-b'), isFalse);
  });

  test('stores completed state separately for each user', () async {
    await dataSource.setCompleted('user-a', true);
    await dataSource.setCompleted('user-b', false);

    expect(await dataSource.isCompleted('user-a'), isTrue);
    expect(await dataSource.isCompleted('user-b'), isFalse);
  });

  test('clear removes all per-user onboarding keys', () async {
    await dataSource.setDismissed('user-a', true);
    await dataSource.setCompleted('user-a', true);
    await dataSource.setDismissed('user-b', true);

    await dataSource.clear();

    expect(await dataSource.isDismissed('user-a'), isFalse);
    expect(await dataSource.isCompleted('user-a'), isFalse);
    expect(await dataSource.isDismissed('user-b'), isFalse);
  });
}
