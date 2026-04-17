import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class ReminderService {
  static final ReminderService instance = ReminderService._();
  static const String _channelId = 'daily_reminder_v4';
  static const int _notificationId = 1001;
  static const MethodChannel _foregroundChannel = MethodChannel('reminder_foreground_service');

  ReminderService._();

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;
  bool _foregroundRunning = false;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;
  bool get foregroundRunning => _foregroundRunning;

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
    
    // 每次都尝试重新调度，确保通知有效
    if (_enabled) {
      await _scheduleDailyReminder();
    }
  }

  /// 启动前台保活服务
  Future<void> startForegroundService() async {
    if (!Platform.isAndroid || _foregroundRunning) return;
    try {
      await _foregroundChannel.invokeMethod('startService');
      _foregroundRunning = true;
      print('[ReminderService] 前台保活服务已启动');
    } catch (e) {
      print('[ReminderService] 启动前台服务失败: $e');
    }
  }

  /// 停止前台保活服务
  Future<void> stopForegroundService() async {
    if (!Platform.isAndroid || !_foregroundRunning) return;
    try {
      await _foregroundChannel.invokeMethod('stopService');
      _foregroundRunning = false;
      print('[ReminderService] 前台保活服务已停止');
    } catch (e) {
      print('[ReminderService] 停止前台服务失败: $e');
    }
  }

  /// 检查电池优化状态
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _foregroundChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 请求忽略电池优化
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      await _foregroundChannel.invokeMethod('requestIgnoreBatteryOptimizations');
      return true;
    } catch (e) {
      return false;
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
      return false;
    }
    return true;
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

  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> checkAndFixReminderState() async {
    if (!_enabled) return true;
    
    final hasPermission = await isNotificationPermissionGranted();
    if (!hasPermission) {
      return false;
    }
    
    try {
      await _scheduleDailyReminder();
      return true;
    } catch (e) {
      return false;
    }
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
        
        // 启动前台保活服务
        await startForegroundService();
      }
    } else {
      // 停止前台服务
      await stopForegroundService();
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
      print('[ReminderService] 开始调度每日提醒，目标时间: $_hour:$_minute');
      
      // 先取消之前的通知
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
        timeoutAfter: 3600000, // 1小时后自动消失
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

      // 计算下次触发时间
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, _hour, _minute, 0);
      
      // 如果今天的时间已经过了，设置为明天
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }
      
      print('[ReminderService] 计算的触发时间: $scheduledTime');

      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
      print('[ReminderService] 时区转换后的时间: $scheduledDate, 时区: ${tz.local.name}');

      // 检查精确闹钟权限
      final canExact = Platform.isAndroid ? await canScheduleExactAlarms() : true;
      print('[ReminderService] 精确闹钟权限: $canExact');
      
      // 调度通知
      if (canExact) {
        print('[ReminderService] 使用精确闹钟模式调度');
        await _plugin.zonedSchedule(
          _notificationId,
          '🔔 AI 人生记录器 - 每日提醒',
          '今天发生了什么新鲜事？来记录一下吧~ 📝\n\n开发者：杰哥网络科技',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'daily_reminder',
        );
      } else {
        print('[ReminderService] 使用不精确闹钟模式调度');
        await _plugin.zonedSchedule(
          _notificationId,
          '🔔 AI 人生记录器 - 每日提醒',
          '今天发生了什么新鲜事？来记录一下吧~ 📝\n\n开发者：杰哥网络科技',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'daily_reminder',
        );
      }
      
      // 验证通知是否已调度
      final pending = await _plugin.pendingNotificationRequests();
      print('[ReminderService] 当前待处理通知数量: ${pending.length}');
      for (var n in pending) {
        print('[ReminderService] 待处理通知 ID: ${n.id}, 标题: ${n.title}');
      }
      
      print('[ReminderService] 每日提醒调度成功');
    } catch (e, stackTrace) {
      print('[ReminderService] 调度失败: $e');
      print('[ReminderService] 堆栈: $stackTrace');
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

  /// 获取通知状态信息（用于调试）
  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final permission = await isNotificationPermissionGranted();
      final canExact = Platform.isAndroid ? await canScheduleExactAlarms() : true;
      
      bool hasScheduledReminder = false;
      for (var n in pending) {
        if (n.id == _notificationId) {
          hasScheduledReminder = true;
          break;
        }
      }

      return {
        'enabled': _enabled,
        'permission': permission,
        'canExactAlarm': canExact,
        'scheduled': hasScheduledReminder,
        'pendingCount': pending.length,
        'targetTime': '$_hour:$_minute',
        'channelId': _channelId,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// 取消所有待处理的通知
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// 强制重新调度通知
  Future<bool> forceReschedule() async {
    try {
      await loadSettings();
      if (_enabled) {
        await _plugin.cancelAll();
        await _scheduleDailyReminder();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取详细的调试信息
  Future<String> getDebugInfo() async {
    final status = await getNotificationStatus();
    final buffer = StringBuffer();
    
    buffer.writeln('=== 推送服务调试信息 ===');
    buffer.writeln('推送开关: ${status['enabled']}');
    buffer.writeln('通知权限: ${status['permission']}');
    buffer.writeln('精确闹钟权限: ${status['canExactAlarm']}');
    buffer.writeln('已调度通知: ${status['scheduled']}');
    buffer.writeln('待处理通知数: ${status['pendingCount']}');
    buffer.writeln('目标时间: ${status['targetTime']}');
    buffer.writeln('通知渠道: ${status['channelId']}');
    
    if (status.containsKey('error')) {
      buffer.writeln('错误: ${status['error']}');
    }
    
    buffer.writeln('========================');
    return buffer.toString();
  }
}
