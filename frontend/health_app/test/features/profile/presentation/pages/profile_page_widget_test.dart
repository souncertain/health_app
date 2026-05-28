import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/domain/entities/profile_stats_snapshot.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';
import 'package:health_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  late MockProfileRepository repository;
  var signOutCalls = 0;

  setUp(() {
    repository = MockProfileRepository();
    signOutCalls = 0;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    when(() => repository.getCachedProfile()).thenAnswer((_) async => null);
    when(
      () => repository.getProfile(),
    ).thenAnswer((_) async => sampleUserProfile(fullName: 'Иван Петров'));
    when(() => repository.getProfileStats()).thenAnswer(
      (_) async => const ProfileStatsSnapshot(
        bloodPressureReadingsCount: 3,
        medicationsCount: 2,
        appointmentsCount: 1,
        daysTracked: 7,
      ),
    );

    await pumpTestApp(
      tester,
      ProfilePage(
        repository: repository,
        onSignOut: () async {
          signOutCalls++;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders profile data and stats from repository', (tester) async {
    await pumpPage(tester);

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(find.text('Мой профиль'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('7'), findsWidgets);
  });

  testWidgets('sign out flow asks for confirmation and calls callback', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из аккаунта?'), findsOneWidget);
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(signOutCalls, 1);
  });

  testWidgets('tapping editable name opens sheet and saves patched profile', (tester) async {
    await pumpPage(tester);
    when(() => repository.saveProfile(any())).thenAnswer((_) async {});

    await tester.tap(find.text('Иван Петров'));
    await tester.pumpAndSettle();

    expect(find.text('Имя и фамилия'), findsAtLeastNWidgets(1));
    await tester.enterText(
      find.byType(TextFormField).first,
      'Мария Иванова',
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final savedProfile = verify(
      () => repository.saveProfile(captureAny()),
    ).captured.single as UserProfile;
    expect(savedProfile.fullName, 'Мария Иванова');
  });
}
