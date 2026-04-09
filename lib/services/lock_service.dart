import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockService {
  static final LockService instance = LockService._();
  static const String _lockKey = 'lock_enabled';
  LocalAuthentication _localAuth = LocalAuthentication();
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

  Future<bool> authenticate() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;
      return await _localAuth.authenticate(
        localizedReason: '请验证身份以进入应用',
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: false,
        ),
      ).timeout(Duration(seconds: 30), onTimeout: () => false);
    } on PlatformException catch (e) {
      if (e.code == 'auth_in_progress' || e.code == 'locked_out') {
        await Future.delayed(Duration(seconds: 2));
      }
      return false;
    }
  }

  Future<void> setLockEnabled(bool enabled) async {
    _lockEnabled = enabled;
    _isLocked = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockKey, enabled);
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
  }
}
