import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class ReminderService {
  static final ReminderService instance = ReminderService._();
  static const String _reminderKey = 'daily_reminder';
  static const String _timeKey = 'reminder_time';

  ReminderService._();

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    await loadSettings();
    await checkAndFixReminderState();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_reminderKey) ?? false;
    final timeJson = prefs.getString(_timeKey);
    if (timeJson != null) {
      try {
        final Map<String, dynamic> time = jsonDecode(timeJson);
        _hour = time['hour'] ?? 20;
        _minute = time['minute'] ?? 0;
      } catch (e) {}
    }
  }

  Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        return await iosPlugin.checkPermissions()?.isEnabled ?? false;
      }
    }
    return false;
  }

  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isPermanentlyDenied;
    }
    return false;
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.requestNotificationsPermission() ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        return await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      }
    }
    return false;
  }

  Future<bool> checkAndFixReminderState() async {
    if (!_enabled) return true;

    final hasPermission = await isNotificationPermissionGranted();
    if (!hasPermission && _enabled) {
      _enabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderKey, false);

      try {
        await _plugin.cancelAll();
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
        await _plugin.cancelAll();
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
    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '\u6BCF\u65E5\u63D0\u9192',
      channelDescription: '\u6BCF\u65E5\u8BB0\u5F55\u63D0\u9192',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _hour,
      _minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1,
      'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
      '\u4ECA\u5929\u53D1\u751F\u4E86\u4EC0\u4E48\u65B0\u9C9C\u4E8B\uFF1F\u6765\u8BB0\u5F55\u4E00\u4E0B\u5427~',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
