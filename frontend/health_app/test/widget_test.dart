import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/main.dart';

void main() {
  testWidgets('Dashboard screen renders key sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HealthApp());

    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text('Latest Reading'), findsOneWidget);
    expect(find.text('BP History'), findsOneWidget);
    expect(find.text('Add Measurement'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });
}
