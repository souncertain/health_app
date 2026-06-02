import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';
import 'package:health_app/features/profile/presentation/pages/profile_onboarding_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  late MockProfileRepository repository;
  var skippedCalls = 0;
  var completedCalls = 0;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockProfileRepository();
    skippedCalls = 0;
    completedCalls = 0;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    when(() => repository.saveProfile(any())).thenAnswer((_) async {});

    await pumpTestApp(
      tester,
      ProfileOnboardingPage(
        initialProfile: sampleUserProfile(
          fullName: 'Иван Петров',
          birthDate: DateTime(1998, 4, 18),
          gender: ProfileGender.male,
          phone: '',
          heightCm: null,
          weightKg: null,
          bloodType: null,
        ),
        repository: repository,
        onSkipped: () async {
          skippedCalls++;
        },
        onCompleted: () async {
          completedCalls++;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'complete button saves profile and finishes onboarding from health step',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      verify(() => repository.saveProfile(any())).called(1);
      expect(completedCalls, 1);
      expect(skippedCalls, 0);
    },
  );
}
