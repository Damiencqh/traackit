import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for Traackit's daily reminder.
///
/// One scheduled notification fires daily at the time the user
/// picks in Settings. iOS handles persistence; even if the app is
/// closed (or rebooted), the schedule survives.
class NotificationService {
  static const _channelId = 'traackit_daily_reminder';
  static const _notificationId = 1;
  static const _testNotificationId = 999;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const initSettings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Asks iOS / Android for permission to display notifications.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    await init();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
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

  /// Schedules (or reschedules) the daily reminder at HH:mm in the user's
  /// local timezone. Pass null to cancel.
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

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(),
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
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  /// Sends an immediate notification — used to test that the
  /// notification system works end-to-end.
  Future<void> sendTestNotification() async {
    await init();
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(),
      android: AndroidNotificationDetails(
        _channelId,
        'Daily reminder',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(
      _testNotificationId,
      'Test notification',
      'If you see this, notifications work.',
      details,
    );
  }
}
