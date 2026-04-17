import 'dart:io';
import 'package:flutter/services.dart';

class ForegroundServicePlugin {
  static const MethodChannel _channel = MethodChannel('reminder_foreground_service');

  static Future<void> startService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      print('[ForegroundService] 启动失败: $e');
    }
  }

  static Future<void> stopService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      print('[ForegroundService] 停止失败: $e');
    }
  }
}
