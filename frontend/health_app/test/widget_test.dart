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

    expect(find.text('Доброе утро'), findsOneWidget);
    expect(find.text('Последнее измерение'), findsOneWidget);

    await tester.tap(find.text('Препараты').first);
    await tester.pumpAndSettle();

    expect(find.text('Препараты'), findsWidgets);
    expect(find.textContaining('Прогресс за '), findsOneWidget);

    await tester.tap(find.text('Главная').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Добавить препарат'), findsWidgets);

    await tester.tap(find.text('Добавить препарат').first);
    await tester.pumpAndSettle();

    expect(find.text('Новый препарат'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Препараты'), findsWidgets);

    await tester.tap(find.text('Метрики').first);
    await tester.pumpAndSettle();

    expect(find.text('Ваши показатели'), findsOneWidget);
    expect(find.text('Сахар в крови'), findsOneWidget);

    await tester.longPress(find.text('Сахар в крови').first);
    await tester.pumpAndSettle();

    expect(find.text('Редактировать метрику'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);

    await tester.ensureVisible(find.text('Удалить'));
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Удалить метрику?'), findsOneWidget);
    expect(
      find.text(
        'Метрика и все сохраненные значения будут удалены из локального хранилища.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Сахар в крови плюс',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'mmol/L');
    await tester.enterText(find.byType(TextFormField).at(2), '75');
    await tester.enterText(find.byType(TextFormField).at(3), '110');
    await tester.ensureVisible(find.text('Обновить метрику'));
    await tester.tap(find.text('Обновить метрику'));
    await tester.pumpAndSettle();

    expect(find.text('Сахар в крови плюс'), findsOneWidget);

    await tester.tap(find.text('Главная').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Записать метрику').first);
    await tester.pumpAndSettle();

    expect(find.text('Выберите метрику'), findsOneWidget);

    await tester.tap(find.text('Сахар в крови плюс').last);
    await tester.pumpAndSettle();

    expect(find.text('Записать Сахар в крови плюс'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Ваши показатели'), findsOneWidget);

    await tester.tap(find.text('Главная').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить давление').first);
    await tester.pumpAndSettle();

    expect(find.text('Сохранить запись'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Доброе утро'), findsOneWidget);

    await tester.tap(find.text('Визиты').first);
    await tester.pumpAndSettle();

    expect(find.text('Визиты к врачу'), findsOneWidget);
    expect(find.text('AI-сканер рецепта'), findsOneWidget);

    await tester.tap(find.text('Главная').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Записать на прием').first);
    await tester.pumpAndSettle();

    expect(find.text('Новая запись'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Визиты к врачу'), findsOneWidget);
  });
}
