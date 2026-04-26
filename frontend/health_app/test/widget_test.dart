import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'New install starts empty and quick actions still open creation flows',
    (tester) async {
      await tester.pumpWidget(const HealthApp());
      await tester.pumpAndSettle();

      expect(find.text('Последние измерения'), findsOneWidget);
      expect(
        find.text('Здесь появятся сохраненные измерения.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Препараты').first);
      await tester.pumpAndSettle();

      expect(find.text('Препараты еще не добавлены'), findsOneWidget);

      await tester.tap(find.text('Метрики').first);
      await tester.pumpAndSettle();

      expect(find.text('Метрик пока нет'), findsOneWidget);

      await tester.tap(find.text('Визиты').first);
      await tester.pumpAndSettle();

      expect(find.text('Разовых визитов пока нет'), findsOneWidget);

      await tester.tap(find.text('Главная').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Добавить препарат'), findsWidgets);
      expect(find.text('Записать метрику'), findsWidgets);
      expect(find.text('Добавить давление'), findsWidgets);
      expect(find.text('Записать на прием'), findsWidgets);

      await tester.tap(find.text('Добавить препарат').first);
      await tester.pumpAndSettle();

      expect(find.text('Новый препарат'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Препараты еще не добавлены'), findsOneWidget);

      await tester.tap(find.text('Главная').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Записать метрику').first);
      await tester.pumpAndSettle();

      expect(find.text('Создать метрику'), findsWidgets);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Метрик пока нет'), findsOneWidget);

      await tester.tap(find.text('Главная').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить давление').first);
      await tester.pumpAndSettle();

      expect(find.text('Сохранить запись'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Последние измерения'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Записать на прием').first);
      await tester.pumpAndSettle();

      expect(find.text('Новая запись'), findsOneWidget);
    },
  );
}
