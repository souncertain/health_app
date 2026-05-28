import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/presentation/pages/auth_gate_page.dart';
import 'package:health_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HealthApp configures material shell for auth flow', (
    tester,
  ) async {
    await tester.pumpWidget(const HealthApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.title, 'Diplom Health');
    expect(materialApp.debugShowCheckedModeBanner, isFalse);
    expect(materialApp.home, isA<AuthGatePage>());
  });

  testWidgets('HealthApp shows auth splash on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(const HealthApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AuthGatePage), findsOneWidget);
  });
}
