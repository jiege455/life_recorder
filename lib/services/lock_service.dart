import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

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

  void showLockScreen(BuildContext context, {required VoidCallback onUnlocked}) {
    if (!_lockEnabled) {
      onUnlocked();
      return;
    }

    getSavedPin().then((savedPin) {
      if (savedPin == null || savedPin.isEmpty) {
        onUnlocked();
        return;
      }

      screenLock(
        context: context,
        correctString: savedPin,
        canCancel: false,
        withBlur: false,
        title: const Text('输入 PIN 码解锁'),
        config: ScreenLockConfig(
          backgroundColor: const Color(0xFF16213E),
          shape: InputButtonShape.circle,
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
        customizedButtonChild: const Icon(Icons.fingerprint, color: Colors.white),
        customizedButtonTap: () async {
          final success = await authenticateWithBiometrics();
          if (success && context.mounted) {
            Navigator.of(context).pop();
            unlock();
            onUnlocked();
          }
        },
        onUnlocked: () {
          unlock();
          onUnlocked();
        },
        onError: (value) {},
      );
    });
  }

  void showCreatePinScreen(BuildContext context, {required VoidCallback onConfirmed}) {
    screenLockCreate(
      context: context,
      digits: 4,
      canCancel: true,
      withBlur: false,
      title: const Text('设置 PIN 码'),
      confirmTitle: const Text('确认 PIN 码'),
      config: ScreenLockConfig(
        backgroundColor: const Color(0xFF16213E),
        shape: InputButtonShape.circle,
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
