import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/meds/domain/entities/medication.dart';
import '../../features/visits/domain/entities/medical_visit.dart';

abstract class NotificationScheduler {
  Future<void> initialize();

  Future<void> syncMedicationNotifications(Iterable<Medication> medications);

  Future<void> cancelMedicationNotifications(String medicationId);

  Future<void> syncVisitNotifications(Iterable<MedicalVisit> visits);

  Future<void> cancelVisitNotification(String visitId);

  Future<void> cancelAllNotifications();
}

class LocalNotificationsService implements NotificationScheduler {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  static const _medicationChannelId = 'medication_reminders';
  static const _visitChannelId = 'visit_reminders';
  static const _maxMedicationSlots = 3;
  static const _notificationsEnabledStorageKey =
      'profile.notifications_enabled';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializationFuture;
  bool _isAvailable = true;

  bool get _supportsNotifications {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<void> initialize() {
    return _initializationFuture ??= _initializeInternal();
  }

  @override
  Future<void> syncMedicationNotifications(
    Iterable<Medication> medications,
  ) async {
    await _runSafely(() async {
      if (!await _notificationsEnabled()) {
        await _plugin.cancelAll();
        return;
      }
      for (final medication in medications) {
        try {
          await _syncMedicationNotification(medication);
        } catch (_) {
          // Skip a broken item without blocking other reminders.
        }
      }
    });
  }

  @override
  Future<void> cancelMedicationNotifications(String medicationId) async {
    await _runSafely(() async {
      await _cancelMedicationNotificationsInternal(medicationId);
    });
  }

  @override
  Future<void> syncVisitNotifications(Iterable<MedicalVisit> visits) async {
    await _runSafely(() async {
      if (!await _notificationsEnabled()) {
        await _plugin.cancelAll();
        return;
      }
      for (final visit in visits) {
        try {
          await _syncVisitNotification(visit);
        } catch (_) {
          // Skip a broken item without blocking other reminders.
        }
      }
    });
  }

  @override
  Future<void> cancelVisitNotification(String visitId) async {
    await _runSafely(() async {
      await _cancelVisitNotificationInternal(visitId);
    });
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _runSafely(() async {
      await _plugin.cancelAll();
    });
  }

  Future<void> _initializeInternal() async {
    if (!_supportsNotifications) {
      return;
    }

    try {
      tz.initializeTimeZones();
      await _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(settings: initializationSettings);
      await _createNotificationChannels();
      await _requestPermissions();
    } on MissingPluginException {
      _isAvailable = false;
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    if (!_supportsNotifications) {
      return;
    }

    try {
      await initialize();
      if (!_isAvailable) {
        return;
      }
      await action();
    } on MissingPluginException {
      _isAvailable = false;
    } catch (_) {
      // Ignore platform scheduling failures so CRUD remains responsive.
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezone.identifier);
      tz.setLocalLocation(location);
    } catch (_) {
      // Keep default timezone fallback if device timezone cannot be resolved.
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _medicationChannelId,
        'Напоминания о препаратах',
        description: 'Уведомления о времени приема лекарств',
        importance: Importance.max,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _visitChannelId,
        'Напоминания о визитах',
        description: 'Уведомления за сутки до визита к врачу',
        importance: Importance.max,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();

      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      if (canScheduleExact != true) {
        await androidPlugin.requestExactAlarmsPermission();
      }
      return;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool> _notificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_notificationsEnabledStorageKey) ?? true;
  }

  Future<void> _syncMedicationNotification(Medication medication) async {
    await _cancelMedicationNotificationsInternal(medication.id);
    if (!medication.notificationsEnabled) {
      return;
    }

    final scheduleMode = await _resolveAndroidScheduleMode();
    final sortedTimes = List<int>.from(medication.timesInMinutes)..sort();

    if (medication.frequency == MedicationFrequency.weekly) {
      final scheduledWeekday = medication.scheduledWeekdays.isEmpty
          ? DateTime.now().weekday
          : medication.scheduledWeekdays.first;

      for (var index = 0; index < sortedTimes.length; index++) {
        await _plugin.zonedSchedule(
          id: _stableNotificationId(
            'med:${medication.id}:w:$scheduledWeekday:$index',
          ),
          title: 'Пора принять препарат',
          body: '${medication.name} • ${medication.dosage}',
          scheduledDate: _nextWeeklyInstance(
            scheduledWeekday,
            sortedTimes[index],
          ),
          notificationDetails: _medicationNotificationDetails,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'medication:${medication.id}',
        );
      }
      return;
    }

    for (var index = 0; index < sortedTimes.length; index++) {
      await _plugin.zonedSchedule(
        id: _stableNotificationId('med:${medication.id}:d:$index'),
        title: 'Пора принять препарат',
        body: '${medication.name} • ${medication.dosage}',
        scheduledDate: _nextDailyInstance(sortedTimes[index]),
        notificationDetails: _medicationNotificationDetails,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medication:${medication.id}',
      );
    }
  }

  Future<void> _syncVisitNotification(MedicalVisit visit) async {
    await _cancelVisitNotificationInternal(visit.id);

    final reminderDateTime = visit.scheduledAt.subtract(
      const Duration(days: 1),
    );
    final scheduledDate = tz.TZDateTime.from(reminderDateTime, tz.local);
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id: _stableNotificationId('visit:${visit.id}'),
      title: 'Напоминание о визите',
      body:
          'Завтра в ${_formatTime(visit.timeInMinutes)} прием у ${visit.doctorName}',
      scheduledDate: scheduledDate,
      notificationDetails: _visitNotificationDetails,
      androidScheduleMode: await _resolveAndroidScheduleMode(),
      payload: 'visit:${visit.id}',
    );
  }

  Future<void> _cancelMedicationNotificationsInternal(
    String medicationId,
  ) async {
    for (var slotIndex = 0; slotIndex < _maxMedicationSlots; slotIndex++) {
      await _plugin.cancel(
        id: _stableNotificationId('med:$medicationId:d:$slotIndex'),
      );
    }

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      for (var slotIndex = 0; slotIndex < _maxMedicationSlots; slotIndex++) {
        await _plugin.cancel(
          id: _stableNotificationId('med:$medicationId:w:$weekday:$slotIndex'),
        );
      }
    }
  }

  Future<void> _cancelVisitNotificationInternal(String visitId) {
    return _plugin.cancel(id: _stableNotificationId('visit:$visitId'));
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final canScheduleExact = await androidPlugin
        .canScheduleExactNotifications();
    return canScheduleExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  NotificationDetails get _medicationNotificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _medicationChannelId,
        'Напоминания о препаратах',
        channelDescription: 'Уведомления о времени приема лекарств',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails get _visitNotificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _visitChannelId,
        'Напоминания о визитах',
        channelDescription: 'Уведомления за сутки до визита к врачу',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextDailyInstance(int minutesInDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesInDay ~/ 60,
      minutesInDay % 60,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  tz.TZDateTime _nextWeeklyInstance(int weekday, int minutesInDay) {
    final now = tz.TZDateTime.now(tz.local);
    final daysUntil =
        (weekday - now.weekday + DateTime.daysPerWeek) % DateTime.daysPerWeek;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesInDay ~/ 60,
      minutesInDay % 60,
    ).add(Duration(days: daysUntil));

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: DateTime.daysPerWeek));
    }

    return scheduled;
  }

  int _stableNotificationId(String key) {
    const offsetBasis = 0x811C9DC5;
    const prime = 0x01000193;

    var hash = offsetBasis;
    for (final codeUnit in key.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0x7fffffff;
    }
    return hash;
  }

  String _formatTime(int totalMinutes) {
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
