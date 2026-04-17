import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

class LockService {
  static final LockService instance = LockService._();
  static const String _lockKey = 'lock_enabled';
  static const String _pinKey = 'lock_pin';
  static const Duration _unlockCooldown = Duration(minutes: 5);

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLocked = false;
  bool _lockEnabled = false;
  DateTime? _lastUnlockTime;

  LockService._();

  bool get isLocked => _isLocked;
  bool get lockEnabled => _lockEnabled;

  Future<void> loadLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = prefs.getBool(_lockKey) ?? false;
    _isLocked = _lockEnabled;
    if (_lockEnabled) {
      _lastUnlockTime = null;
    }
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
      // 检查设备是否支持
      final isSupported = await _localAuth.isDeviceSupported();
      debugPrint('设备是否支持生物识别：$isSupported');
      if (!isSupported) {
        debugPrint('设备不支持生物识别');
        return false;
      }

      // 检查是否可以使用生物识别
      final canCheckBiometricsValue = await _localAuth.canCheckBiometrics;
      debugPrint('是否可以检查生物识别：$canCheckBiometricsValue');
      if (!canCheckBiometricsValue) {
        debugPrint('无法使用生物识别');
        return false;
      }
      
      // 执行生物识别验证
      final authenticated = await _localAuth.authenticate(
        localizedReason: '请验证身份以进入应用',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 改为 false，允许使用设备密码
        ),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );

      if (authenticated) {
        debugPrint('生物识别验证成功');
      } else {
        debugPrint('生物识别验证失败');
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('生物识别异常：${e.code} - ${e.message}');
      
      // 处理特定的错误码
      if (e.code == 'NotEnrolledException') {
        debugPrint('用户未录入生物特征');
      } else if (e.code == 'LockoutException') {
        debugPrint('生物识别被锁定，请稍后重试');
        await Future.delayed(const Duration(seconds: 5));
      } else if (e.code == 'AuthenticationFailed') {
        debugPrint('生物识别验证失败');
      } else if (e.code == 'UserCancelException') {
        debugPrint('用户取消了生物识别');
      }
      
      return false;
    } catch (e) {
      debugPrint('生物识别未知错误：$e');
      return false;
    }
  }

  Future<String?> getSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await getSavedPin();
    if (savedPin == null || savedPin.isEmpty) return false;
    return pin == savedPin;
  }

  void showCreatePinScreen(BuildContext context, {required VoidCallback onConfirmed}) {
    screenLockCreate(
      context: context,
      digits: 4,
      canCancel: true,
      useBlur: false,
      title: const Text('设置 PIN 码'),
      confirmTitle: const Text('确认 PIN 码'),
      config: ScreenLockConfig(
        backgroundColor: const Color(0xFF16213E),
      ),
      secretsConfig: SecretsConfig(
        spacing: 16,
        padding: const EdgeInsets.all(16),
      ),
      keyPadConfig: KeyPadConfig(
        buttonConfig: KeyPadButtonConfig(
          buttonStyle: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
      onConfirmed: (pin) async {
        await setPin(pin);
        if (context.mounted) {
          Navigator.of(context).pop();
          onConfirmed();
        }
      },
    );
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
    _lastUnlockTime = DateTime.now();
  }

  void lock() {
    if (_lockEnabled) {
      _isLocked = true;
    }
  }

  bool shouldLock() {
    if (!_lockEnabled) return false;
    if (_lastUnlockTime == null) return true;
    return DateTime.now().difference(_lastUnlockTime!) > _unlockCooldown;
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
