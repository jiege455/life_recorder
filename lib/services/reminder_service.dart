import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class ReminderService {
  static final ReminderService instance = ReminderService._();
  static const String _reminderKey = 'daily_reminder';
  static const String _timeKey = 'reminder_time';
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  ReminderService._();

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    await _notifications.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_reminderKey) ?? false;
    final timeJson = prefs.getString(_timeKey);
    if (timeJson != null) {
      final Map<String, dynamic> time = jsonDecode(timeJson);
      _hour = time['hour'] ?? 20;
      _minute = time['minute'] ?? 0;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderKey, enabled);
    if (enabled) {
      await _scheduleNotification();
    } else {
      await _notifications.cancelAll();
    }
  }

  Future<void> setTime(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, jsonEncode({'hour': hour, 'minute': minute}));
    if (_enabled) {
      await _scheduleNotification();
    }
  }

  Future<void> _scheduleNotification() async {
    await _notifications.cancelAll();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, _hour, _minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      0,
      'AI人生记录器',
      '今天发生了什么新鲜事？来记录一下吧~',
      tzScheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          '每日提醒',
          channelDescription: '每日记录提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
