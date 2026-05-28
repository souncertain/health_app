import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/mocks.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerTestFallbackValues();
  await testMain();
}
