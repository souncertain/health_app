import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/health_app.dart';
import 'core/services/local_notifications_service.dart';

export 'app/health_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(LocalNotificationsService.instance.initialize());
  runApp(const HealthApp());
}
