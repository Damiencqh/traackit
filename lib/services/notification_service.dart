import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelId = 'traackit_daily_reminder';
  static const _notificationId = 1;
  static const _testNotificationId = 999;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    developer.log('NotificationService.init() starting', name: 'traackit');

    tz_data.initializeTimeZones();

    // CRITICAL: ask the device for its current timezone and set tz.local.
    // Without this, tz.local defaults to UTC and scheduled times are off.
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
      developer.log('Set local timezone to: $localName', name: 'traackit');
    } catch (e) {
      developer.log('Failed to set local timezone: $e — falling back to UTC',
          name: 'traackit');
    }

    const initSettings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    final ok = await _plugin.initialize(initSettings);
    developer.log('NotificationService.init() returned: $ok', name: 'traackit');
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    developer.log('requestPermission() called', name: 'traackit');

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      developer.log('iOS requestPermissions returned: $granted',
          name: 'traackit');
      return granted ?? false;
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  Future<void> scheduleDailyReminder(String? hhmm) async {
    await init();
    await _plugin.cancel(_notificationId);
    if (hhmm == null) return;

    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 10;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    developer.log(
        'Scheduling reminder for $scheduled (local zone: ${tz.local.name})',
        name: 'traackit');

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
      android: AndroidNotificationDetails(
        _channelId,
        'Daily reminder',
        channelDescription: 'A gentle nudge to capture today\'s photo.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.zonedSchedule(
      _notificationId,
      'Time to traack.',
      'A photo a day keeps the gap away.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> sendTestNotification() async {
    await init();
    developer.log('sendTestNotification() called', name: 'traackit');

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
      android: AndroidNotificationDetails(
        _channelId,
        'Daily reminder',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    try {
      await _plugin.show(
        _testNotificationId,
        'Test notification',
        'If you see this, notifications work.',
        details,
      );
      developer.log('Notification show() completed without exception',
          name: 'traackit');
    } catch (e, stack) {
      developer.log('Notification show() threw: $e',
          name: 'traackit', error: e, stackTrace: stack);
    }
  }
}
