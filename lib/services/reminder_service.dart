import 'dart:io';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class ReminderService {
  static final ReminderService instance = ReminderService._();
  static const String _reminderKey = 'daily_reminder';
  static const String _timeKey = 'reminder_time';

  ReminderService._();

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'daily_reminder',
          channelName: '每日提醒',
          channelDescription: '每日记录提醒',
          defaultColor: Color(0xFF4A90E2),
          ledColor: Color(0xFF4A90E2),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
        ),
      ],
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
    return await AwesomeNotifications().isNotificationAllowed();
  }

  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isPermanentlyDenied;
    }
    return false;
  }

  Future<void> openNotificationSettings() async {
    await AwesomeNotifications().openNotificationSettingsPage();
  }

  Future<bool> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  Future<bool> checkAndFixReminderState() async {
    if (!_enabled) return true;
    
    final hasPermission = await isNotificationPermissionGranted();
    if (!hasPermission && _enabled) {
      _enabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderKey, false);
      
      try {
        await AwesomeNotifications().cancelAllSchedules();
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
        await AwesomeNotifications().cancelAllSchedules();
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
    await AwesomeNotifications().cancelAllSchedules();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'daily_reminder',
        title: 'AI人生记录器',
        body: '今天发生了什么新鲜事？来记录一下吧~',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: _hour,
        minute: _minute,
        second: 0,
        repeats: true,
      ),
    );
  }
}
