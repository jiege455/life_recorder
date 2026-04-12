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
  static const String _channelId = 'daily_reminder_v3';
  static const int _notificationId = 1001;

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

    debugPrint('========================================');
    debugPrint('ReminderService 开始初始化');
    debugPrint('========================================');

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      debugPrint('✅ 时区初始化成功：Asia/Shanghai');
    } catch (e) {
      debugPrint('⚠️ 设置亚洲/上海时区失败，尝试 UTC: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        debugPrint('✅ 时区设置为 UTC');
      } catch (e2) {
        debugPrint('❌ 时区设置全部失败：$e2');
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📱 收到通知响应：${response.id} - ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const channel = AndroidNotificationChannel(
            'daily_reminder_v3',
            '每日提醒',
            description: '每日记录提醒 - 请勿关闭此频道的通知',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          );
          await androidPlugin.createNotificationChannel(channel);
          debugPrint('✅ 通知频道已创建：daily_reminder_v3');
        }
      } catch (e) {
        debugPrint('❌ 创建通知频道失败：$e');
      }
    }

    await loadSettings();
    await checkAndFixReminderState();

    if (_enabled) {
      debugPrint('📅 应用启动，启用状态为开，开始调度每日提醒...');
      try {
        await _scheduleNotification();
      } catch (e) {
        debugPrint('❌ 应用启动时重新调度通知失败：$e');
      }
    }

    _isInitialized = true;
    debugPrint('========================================');
    debugPrint('ReminderService 初始化完成');
    debugPrint('========================================');
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
    debugPrint('📋 加载设置：enabled=$_enabled, time=${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}');
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
          debugPrint('🔔 Android 通知权限请求结果：$granted');
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
          debugPrint('🔔 iOS 通知权限请求结果：$granted');
          return granted;
        }
      }
      debugPrint('⚠️ 无法获取平台特定实现，假设权限已授予');
      return true;
    } catch (e) {
      debugPrint('❌ 请求通知权限时出错：$e');
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canExact = await androidPlugin.canScheduleExactNotifications() ?? false;
        debugPrint('⏰ 精确闹钟权限检查：$canExact');
        return canExact;
      }
    } catch (e) {
      debugPrint('❌ 检查精确闹钟权限失败：$e');
    }
    return false;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestExactAlarmsPermission() ?? false;
        debugPrint('⏰ 精确闹钟权限请求结果：$granted');
        
        if (!granted) {
          debugPrint('⚠️ 用户拒绝了精确闹钟权限，将使用不精确模式');
        }
        
        return granted;
      }
    } catch (e) {
      debugPrint('❌ 请求精确闹钟权限失败：$e');
    }
    return false;
  }

  Future<bool> checkBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      final isDisabled = status.isGranted || status.isLimited;
      
      if (!isDisabled) {
        debugPrint('🔋 电池优化未关闭，可能导致后台通知延迟');
      } else {
        debugPrint('✅ 电池优化已关闭（或受限模式）');
      }
      
      return isDisabled;
    } catch (e) {
      debugPrint('❌ 检查电池优化状态失败：$e');
      return false;
    }
  }

  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) {
        debugPrint('🔋 请求关闭电池优化...');
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('❌ 请求关闭电池优化失败：$e');
    }
  }

  Future<bool> checkAndFixReminderState() async {
    if (!_enabled) return true;

    final hasPermission = await isNotificationPermissionGranted();
    if (!hasPermission && _enabled) {
      debugPrint('⚠️ 通知权限被撤销，禁用提醒功能');
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
    debugPrint('========================================');
    debugPrint('⚙️ 设置提醒状态：$enabled');
    debugPrint('========================================');

    if (enabled) {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        debugPrint('❌ 通知权限被拒绝，无法启用提醒');
        _enabled = false;
        return false;
      }

      if (Platform.isAndroid) {
        final canExact = await canScheduleExactAlarms();
        if (!canExact) {
          debugPrint('⚠️ 没有精确闹钟权限，尝试请求...');
          final granted = await requestExactAlarmPermission();
          
          if (!granted) {
            debugPrint('⚠️ 精确闹钟权限被拒绝，将使用不精确模式（可能延迟几分钟）');
            
            final batteryOk = await checkBatteryOptimizationDisabled();
            if (!batteryOk) {
              debugPrint('💡 建议：请在系统设置中关闭本应用的电池优化，以确保准时提醒');
            }
          }
        } else {
          debugPrint('✅ 精确闹钟权限已授予');
        }
      }
    }

    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderKey, enabled);

    if (enabled) {
      try {
        await _scheduleNotification();
        debugPrint('✅ 提醒功能已启用');
      } catch (e) {
        debugPrint('❌ 调度通知失败：$e');
        _enabled = false;
        await prefs.setBool(_reminderKey, false);
        return false;
      }
    } else {
      try {
        await _plugin.cancelAll();
        debugPrint('✅ 已取消所有通知');
      } catch (e) {}
    }

    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, jsonEncode({'hour': hour, 'minute': minute}));
    debugPrint('⏰ 设置提醒时间：${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

    if (_enabled) {
      try {
        await _scheduleNotification();
      } catch (e) {
        debugPrint('❌ 重新调度通知失败：$e');
      }
    }
  }

  Future<void> rescheduleIfEnabled() async {
    debugPrint('🔄 重新检查并调度提醒...');
    
    if (_enabled) {
      try {
        await _scheduleNotification();
        debugPrint('✅ 重新调度成功');
      } catch (e) {
        debugPrint('❌ 重新调度失败：$e');
      }
    }
  }

  Future<void> _scheduleNotification() async {
    debugPrint('----------------------------------------');
    debugPrint('📅 开始调度定时通知');
    debugPrint('----------------------------------------');

    await _plugin.cancelAll();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      '每日提醒',
      channelDescription: '每日记录提醒',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
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

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _hour,
      _minute,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('📍 当前时间：$now');
    debugPrint('🎯 计划通知时间：$scheduledDate');
    debugPrint('🌍 时区：${tz.local.name}');
    debugPrint('⏱️ 距离通知还有：${scheduledDate.difference(now).inMinutes} 分钟');
    debugPrint('📢 通知频道ID：$_channelId');
    debugPrint('🆔 通知ID：$_notificationId');

    bool canExact = true;
    if (Platform.isAndroid) {
      canExact = await canScheduleExactAlarms();
      debugPrint('⏰ 精确闹钟权限：$canExact');
      
      final batteryOk = await checkBatteryOptimizationDisabled();
      debugPrint('🔋 电池优化状态：${batteryOk ? "已关闭" : "未关闭（可能影响准时性）"}');
    }

    try {
      if (canExact) {
        debugPrint('🚀 使用精确模式调度...');
        
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
        
        debugPrint('✅ 每日提醒已设置（精确模式）');
        debugPrint('   时间：${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}');
        debugPrint('   模式：exactAllowWhileIdle（即使Doze模式也会触发）');
      } else {
        debugPrint('⚠️ 使用不精确模式调度（可能延迟几分钟）...');
        
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
        
        debugPrint('✅ 每日提醒已设置（不精确模式）');
        debugPrint('   时间：${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}');
        debugPrint('   模式：inexactAllowWhileIdle');
        debugPrint('   ⚠️ 注意：可能比设定时间晚几分钟');
      }
      
      debugPrint('----------------------------------------');
      debugPrint('✅ 调度完成！');
      debugPrint('----------------------------------------');
    } catch (e) {
      debugPrint('❌ 调度失败：$e');
      debugPrint('----------------------------------------');
      rethrow;
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      final hasPermission = await isNotificationPermissionGranted();
      if (!hasPermission) {
        debugPrint('❌ 没有通知权限，无法发送测试通知');
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
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
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
        '如果您收到这条通知，说明通知功能正常工作！✅\n\n但如果定时提醒不工作，请检查：\n1. 是否授予了"精确闹钟"权限\n2. 是否关闭了电池优化\n3. 开发者：杰哥网络科技',
        notificationDetails,
      );

      debugPrint('✅ 测试通知已发送');
      return true;
    } catch (e) {
      debugPrint('❌ 发送测试通知失败：$e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDebugInfo() async {
    final now = tz.TZDateTime.now(tz.local);
    final canExact = await canScheduleExactAlarms();
    final hasNotifPerm = await isNotificationPermissionGranted();
    final batteryOk = await checkBatteryOptimizationDisabled();
    
    var nextTriggerTime = '未设置';
    if (_enabled) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        _hour,
        _minute,
        0,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate.add(const Duration(days: 1));
      }
      nextTriggerTime = scheduledDate.toString();
    }
    
    return {
      'enabled': _enabled,
      'hour': _hour,
      'minute': _minute,
      'timezone': tz.local.name,
      'currentTime': now.toString(),
      'nextTriggerTime': nextTriggerTime,
      'canScheduleExactAlarms': canExact,
      'hasNotificationPermission': hasNotifPerm,
      'batteryOptimizationDisabled': batteryOk,
      'isInitialized': _isInitialized,
      'channelId': _channelId,
      'notificationId': _notificationId,
      'platform': Platform.operatingSystem,
      'androidVersion': Platform.isAndroid ? '需要检查' : 'N/A',
    };
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      debugPrint('📋 当前待处理的通知数量：${pendingNotifications.length}');
      
      return pendingNotifications.map((n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'payload': n.payload,
      }).toList();
    } catch (e) {
      debugPrint('❌ 获取待处理通知失败：$e');
      return [];
    }
  }

  Future<void> forceReschedule() async {
    debugPrint('🔄 强制重新调度所有通知...');
    
    if (_enabled) {
      try {
        await _scheduleNotification();
        debugPrint('✅ 强制重新调度成功');
      } catch (e) {
        debugPrint('❌ 强制重新调度失败：$e');
        rethrow;
      }
    } else {
      debugPrint('⚠️ 提醒功能未启用，跳过调度');
    }
  }
}
