import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/test_data.dart';

void main() {
  late AuthLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = AuthLocalDataSource();
  });

  test('getSession returns null when storage is empty', () async {
    expect(await dataSource.getSession(), isNull);
  });

  test('saveSession persists and returns stored session', () async {
    final session = sampleAuthSessionModel();

    await dataSource.saveSession(session);

    final restored = await dataSource.getSession();
    expect(restored?.userId, session.userId);
    expect(restored?.accessToken, session.accessToken);
  });

  test('getSession returns cached session after first read', () async {
    final session = sampleAuthSessionModel(userId: 'cached-user');
    await dataSource.saveSession(session);

    final first = await dataSource.getSession();
    final second = await dataSource.getSession();

    expect(identical(first, second), isTrue);
  });

  test('clearSession removes stored session', () async {
    await dataSource.saveSession(sampleAuthSessionModel());

    await dataSource.clearSession();

    expect(await dataSource.getSession(), isNull);
  });
}
