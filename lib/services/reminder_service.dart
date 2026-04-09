import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (e) {
      try {
        tz.setLocalLocation(tz.local);
      } catch (e2) {}
    }
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

  Future<bool> isNotificationPermissionGranted() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        return status.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.notification.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) return false;
        final result = await Permission.notification.request();
        if (result.isGranted) return true;
        if (result.isPermanentlyDenied) return false;
        return result.isGranted;
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true)
              .timeout(Duration(seconds: 10), onTimeout: () => false);
          if (granted == false) return false;
        }
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> checkAndFixReminderState() async {
    if (!_enabled) return true;
    final hasPermission = await isNotificationPermissionGranted();
    if (!hasPermission && _enabled) {
      _enabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderKey, false);
      try {
        await _notifications.cancelAll();
      } catch (e) {}
      return false;
    }
    return true;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        _enabled = false;
        return false;
      }
    }
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderKey, enabled);
    if (enabled) {
      try {
        await _scheduleNotification();
      } catch (e) {
        _enabled = false;
        await prefs.setBool(_reminderKey, false);
        return false;
      }
    } else {
      try {
        await _notifications.cancelAll();
      } catch (e) {}
    }
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, jsonEncode({'hour': hour, 'minute': minute}));
    if (_enabled) {
      try {
        await _scheduleNotification();
      } catch (e) {}
    }
  }

  Future<void> _scheduleNotification() async {
    await _notifications.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, _hour, _minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
      '\u4ECA\u5929\u53D1\u751F\u4E86\u4EC0\u4E48\u65B0\u9C9C\u4E8B\uFF1F\u6765\u8BB0\u5F55\u4E00\u4E0B\u5427~',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          '\u6BCF\u65E5\u63D0\u9192',
          channelDescription: '\u6BCF\u65E5\u8BB0\u5F55\u63D0\u9192',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
