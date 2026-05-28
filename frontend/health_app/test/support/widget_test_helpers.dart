import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  NavigatorObserver? navigatorObserver,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: child),
      navigatorObservers: navigatorObserver == null
          ? const <NavigatorObserver>[]
          : [navigatorObserver],
    ),
  );

  await tester.pump();
}

Widget buildSheetLauncher({
  required String buttonLabel,
  required Future<void> Function(BuildContext context) onOpen,
}) {
  return Builder(
    builder: (context) {
      return Center(
        child: ElevatedButton(
          onPressed: () => onOpen(context),
          child: Text(buttonLabel),
        ),
      );
    },
  );
}
