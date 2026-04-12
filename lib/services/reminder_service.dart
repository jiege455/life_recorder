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
  static const String _channelId = 'daily_reminder_v4';
  static const int _notificationId = 1001;

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
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (e2) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          _channelId,
          '每日提醒',
          description: '每日记录提醒',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    await loadSettings();
    
    if (_enabled) {
      await _scheduleDailyReminder();
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('daily_reminder_enabled') ?? false;
    final timeJson = prefs.getString('reminder_time');
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
    }
    return false;
  }

  Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          return await androidPlugin.requestNotificationsPermission() ?? false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.canScheduleExactNotifications() ?? false;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.requestExactAlarmsPermission() ?? false;
      }
    } catch (e) {}
    return false;
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        return false;
      }

      if (Platform.isAndroid) {
        final canExact = await canScheduleExactAlarms();
        if (!canExact) {
          await requestExactAlarmPermission();
        }
      }
    }

    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);

    if (enabled) {
      try {
        await _scheduleDailyReminder();
      } catch (e) {
        _enabled = false;
        await prefs.setBool('daily_reminder_enabled', false);
        return false;
      }
    } else {
      try {
        await _plugin.cancel(_notificationId);
      } catch (e) {}
    }

    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_time', jsonEncode({'hour': hour, 'minute': minute}));

    if (_enabled) {
      await _scheduleDailyReminder();
    }
  }

  Future<void> rescheduleIfEnabled() async {
    if (_enabled) {
      await _scheduleDailyReminder();
    }
  }

  Future<void> _scheduleDailyReminder() async {
    try {
      await _plugin.cancel(_notificationId);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        '每日提醒',
        channelDescription: '每日记录提醒',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        playSound: true,
        fullScreenIntent: true,
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, _hour, _minute, 0);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }

      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      final canExact = Platform.isAndroid ? await canScheduleExactAlarms() : true;
      
      if (canExact) {
        await _plugin.zonedSchedule(
          _notificationId,
          '🔔 AI 人生记录器 - 每日提醒',
          '今天发生了什么新鲜事？来记录一下吧~ 📝\n\n开发者：杰哥网络科技',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'daily_reminder',
        );
      } else {
        await _plugin.zonedSchedule(
          _notificationId,
          '🔔 AI 人生记录器 - 每日提醒',
          '今天发生了什么新鲜事？来记录一下吧~ 📝\n\n开发者：杰哥网络科技',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'daily_reminder',
        );
      }
    } catch (e) {
      debugPrint('❌ 调度失败：$e');
      rethrow;
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      final hasPermission = await isNotificationPermissionGranted();
      if (!hasPermission) {
        return false;
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        '每日提醒',
        channelDescription: '每日记录提醒',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        autoCancel: true,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        playSound: true,
        fullScreenIntent: true,
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        999,
        '🔔 AI 人生记录器 - 测试通知',
        '如果您收到这条通知，说明通知功能正常工作！✅\n\n开发者：杰哥网络科技',
        notificationDetails,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
