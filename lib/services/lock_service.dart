import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';

class LockService {
  static final LockService instance = LockService._();
  static const String _lockKey = 'lock_enabled';
  static const String _pinKey = 'lock_pin';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLocked = false;
  bool _lockEnabled = false;

  LockService._();

  bool get isLocked => _isLocked;
  bool get lockEnabled => _lockEnabled;

  Future<void> loadLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = prefs.getBool(_lockKey) ?? false;
    _isLocked = _lockEnabled;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;
      return await _localAuth.authenticate(
        localizedReason: '请验证身份以进入应用',
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
        ),
      ).timeout(const Duration(seconds: 30), onTimeout: () => false);
    } on PlatformException catch (e) {
      if (e.code == 'auth_in_progress' || e.code == 'locked_out') {
        await Future.delayed(const Duration(seconds: 2));
      }
      return false;
    }
  }

  void showLockScreen(BuildContext context, {required VoidCallback onUnlocked}) {
    if (!_lockEnabled) {
      onUnlocked();
      return;
    }

    String? enteredPin;
    
    ScreenLock(
      correctString: '',
      title: '输入 PIN 码',
      customizedButtonChild: const Icon(Icons.fingerprint),
      customizedButtonTap: () async {
        final success = await authenticateWithBiometrics();
        if (success && context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
      onConfirmed: (pin) async {
        enteredPin = pin;
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString(_pinKey);

        if (savedPin == null || savedPin.isEmpty) {
          // 首次设置 PIN
          await prefs.setString(_pinKey, pin);
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
          return true;
        } else if (pin == savedPin) {
          // 验证成功
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
          return true;
        } else {
          // PIN 错误
          return false;
        }
      },
      footer: TextButton(
        onPressed: () => _showResetDialog(context),
        child: const Text('忘记密码？'),
      ),
    ).show(context).then((value) {
      if (value == true) {
        unlock();
        onUnlocked();
      }
    });
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置密码'),
        content: const Text('确定要重置 PIN 码吗？需要重新设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> setLockEnabled(bool enabled) async {
    _lockEnabled = enabled;
    _isLocked = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockKey, enabled);
    
    if (!enabled) {
      await prefs.remove(_pinKey);
    }
  }

  void unlock() {
    _isLocked = false;
  }

  void lock() {
    if (_lockEnabled) {
      _isLocked = true;
    }
  }

  Future<void> disableLock() async {
    _lockEnabled = false;
    _isLocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockKey, false);
    await prefs.remove(_pinKey);
  }

  Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    return pin != null && pin.isNotEmpty;
  }
}
