import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shell switches between dashboard, meds, metrics, and visits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HealthApp());
    await tester.pumpAndSettle();

    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text('Latest Reading'), findsOneWidget);

    await tester.tap(find.text('Meds').first);
    await tester.pumpAndSettle();

    expect(find.text('Medications'), findsOneWidget);
    expect(find.text("Today's Progress"), findsOneWidget);

    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Medication'), findsWidgets);

    await tester.tap(find.text('Add Medication').first);
    await tester.pumpAndSettle();

    expect(find.text('Medications'), findsOneWidget);

    await tester.tap(find.text('Metrics').first);
    await tester.pumpAndSettle();

    expect(find.text('Your Numbers'), findsOneWidget);
    expect(find.text('Blood Sugar'), findsOneWidget);

    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log Metric').first);
    await tester.pumpAndSettle();

    expect(find.text('Your Numbers'), findsOneWidget);

    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add BP Reading').first);
    await tester.pumpAndSettle();

    expect(find.text('Save Reading'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Good Morning'), findsOneWidget);

    await tester.tap(find.text('Visits').first);
    await tester.pumpAndSettle();

    expect(find.text('Medical Visits'), findsOneWidget);
    expect(find.text('AI Prescription Scanner'), findsOneWidget);

    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book Appointment').first);
    await tester.pumpAndSettle();

    expect(find.text('Medical Visits'), findsOneWidget);
  });
}
