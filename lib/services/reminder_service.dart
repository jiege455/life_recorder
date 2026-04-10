import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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
  bool _isInitialized = false;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      debugPrint('时区初始化成功：Asia/Shanghai');
    } catch (e) {
      debugPrint('设置亚洲/上海时区失败，尝试 UTC: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        debugPrint('时区设置为 UTC');
      } catch (e2) {
        debugPrint('时区设置全部失败：$e2');
      }
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

    await loadSettings();
    await checkAndFixReminderState();
    _isInitialized = true;
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
        final result = await iosPlugin.checkPermissions();
        return result?.isEnabled ?? false;
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
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission() ?? false;
          debugPrint('Android 通知权限请求结果：$granted');
          return granted;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
          debugPrint('iOS 通知权限请求结果：$granted');
          return granted;
        }
      }
      debugPrint('无法获取平台特定实现，假设权限已授予');
      return true;
    } catch (e) {
      debugPrint('请求通知权限时出错：$e');
      return false;
    }
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
        debugPrint('调度通知失败: $e');
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
      } catch (e) {
        debugPrint('重新调度通知失败: $e');
      }
    }
  }

  Future<void> _scheduleNotification() async {
    await _plugin.cancelAll();

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '每日提醒',
      channelDescription: '每日记录提醒 - 强势推送',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      visibility: NotificationVisibility.public,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: NotificationInterruptionLevel.timeSensitive,
    );
    final notificationDetails = NotificationDetails(
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

    debugPrint('当前时间: $now');
    debugPrint('计划通知时间: $scheduledDate');
    debugPrint('时区: ${tz.local.name}');

    try {
      await _plugin.zonedSchedule(
        1,
        '🔔 AI 人生记录器 - 每日提醒',
        '今天发生了什么新鲜事？来记录一下吧~ 📝',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('每日提醒已设置（强势推送模式），时间：${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('精确调度失败，尝试不精确模式: $e');
      try {
        await _plugin.zonedSchedule(
          1,
          '🔔 AI 人生记录器 - 每日提醒',
          '今天发生了什么新鲜事？来记录一下吧~ 📝',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('每日提醒已设置（不精确模式），时间：${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}');
      } catch (e2) {
        debugPrint('通知调度完全失败: $e2');
        rethrow;
      }
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      final hasPermission = await isNotificationPermissionGranted();
      if (!hasPermission) {
        debugPrint('没有通知权限，无法发送测试通知');
        return false;
      }

      final androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        '每日提醒',
        channelDescription: '每日记录提醒 - 强势推送',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        autoCancel: false,
        ongoing: true,
        visibility: NotificationVisibility.public,
      );
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: NotificationInterruptionLevel.timeSensitive,
      );
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        999,
        '🔔 AI 人生记录器 - 测试通知',
        '如果您收到这条通知，说明每日提醒功能正常工作！✅ 现在就开始记录今天的心情吧~ 📝',
        notificationDetails,
      );

      debugPrint('测试通知已发送');
      return true;
    } catch (e) {
      debugPrint('发送测试通知失败：$e');
      return false;
    }
  }
}
