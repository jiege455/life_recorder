import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _showPinDialog(context, onUnlocked);
  }

  void _showPinDialog(BuildContext context, VoidCallback onUnlocked) {
    String pin = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('输入 PIN 码'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '请输入 4-6 位 PIN 码',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      pin = value;
                    },
                    onSubmitted: (value) async {
                      final success = await _validatePin(value);
                      if (success && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        unlock();
                        onUnlocked();
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: canCheckBiometrics(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return TextButton.icon(
                          onPressed: () async {
                            final success = await authenticateWithBiometrics();
                            if (success && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              unlock();
                              onUnlocked();
                            }
                          },
                          icon: Icon(Icons.fingerprint),
                          label: Text('使用生物识别'),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await _validatePin(pin);
                    if (success && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      unlock();
                      onUnlocked();
                    } else if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('PIN 码错误'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _validatePin(String inputPin) async {
    if (inputPin.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);

    if (savedPin == null || savedPin.isEmpty) {
      await prefs.setString(_pinKey, inputPin);
      return true;
    }
    return inputPin == savedPin;
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
