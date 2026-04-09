import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/user_agreement_page.dart';
import 'services/theme_service.dart';
import 'services/lock_service.dart';
import 'services/reminder_service.dart';
import 'services/tag_service.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final themeService = await ThemeService.getInstance();
  await themeService.loadThemeMode();
  await LockService.instance.loadLockStatus();
  await ReminderService.instance.initialize();
  await TagService.instance.loadTags();

  runApp(LifeRecorderApp(themeService: themeService));
}

class LifeRecorderApp extends StatefulWidget {
  final ThemeService themeService;

  const LifeRecorderApp({super.key, required this.themeService});

  @override
  State<LifeRecorderApp> createState() => _LifeRecorderAppState();
}

class _LifeRecorderAppState extends State<LifeRecorderApp> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _lockEnabled = false;
  bool _agreedToPolicy = false;
  bool _hasCheckedPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockEnabled = LockService.instance.lockEnabled;
    _isLocked = _lockEnabled;
    _checkPolicyAgreement();
  }

  Future<void> _checkPolicyAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('agreed_to_policy') ?? false;
    if (mounted) {
      setState(() {
        _agreedToPolicy = agreed;
      });
    }
  }

  Future<void> _agreeToPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agreed_to_policy', true);
    if (mounted) {
      setState(() {
        _agreedToPolicy = true;
      });
    }
  }

  void _checkNotificationPermissionOnStart() {
    if (_hasCheckedPermission) return;
    _hasCheckedPermission = true;
    ReminderService.instance.checkAndFixReminderState().then((ok) {
      if (!ok && mounted) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          _showPermissionRevokedDialog(context);
        }
      }
    });
  }

  void _showPermissionRevokedDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('通知权限已关闭'),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          '您之前已启用每日提醒功能，但通知权限已被关闭。每日提醒将无法正常工作，请前往系统设置重新开启通知权限。',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('暂不设置'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ReminderService.instance.openNotificationSettings();
            },
            icon: Icon(Icons.settings, size: 18),
            label: Text('去设置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentLockEnabled = LockService.instance.lockEnabled;
      if (currentLockEnabled && !_isLocked) {
        setState(() {
          _lockEnabled = currentLockEnabled;
          _isLocked = true;
        });
      } else if (!currentLockEnabled && _isLocked) {
        setState(() {
          _lockEnabled = false;
          _isLocked = false;
        });
      }
    }
  }

  void _unlock() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: widget.themeService.themeMode,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_agreedToPolicy) {
      return _PolicyConsentScreen(onAgree: _agreeToPolicy);
    }
    if (_isLocked && _lockEnabled) {
      return LockScreen(onUnlock: _unlock);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermissionOnStart();
    });
    return const HomePage();
  }
}

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  int _failedAttempts = 0;
  bool _showEmergencyUnlock = false;

  void _showScreenLock() async {
    final lockService = LockService.instance;
    final savedPin = await lockService.getSavedPin();
    if (savedPin == null || savedPin.isEmpty) {
      lockService.unlock();
      widget.onUnlock();
      return;
    }

    screenLock(
      context: context,
      correctString: savedPin,
      canCancel: false,
      withBlur: false,
      title: Text('输入 PIN 码解锁'),
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
        final success = await lockService.authenticateWithBiometrics();
        if (success && mounted) {
          Navigator.of(context).pop();
          lockService.unlock();
          widget.onUnlock();
        }
      },
      onUnlocked: () {
        _failedAttempts = 0;
        lockService.unlock();
        widget.onUnlock();
      },
      onError: (value) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          setState(() => _showEmergencyUnlock = true);
        }
      },
    );
  }

  Future<void> _emergencyUnlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('紧急解锁'),
        content: Text('这将关闭隐私锁功能并进入应用。您可以在设置中重新启用隐私锁。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('确认解锁', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LockService.instance.disableLock();
      widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A90E2), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'AI人生记录器',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '已启用隐私保护',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    if (_failedAttempts > 0) ...[
                      SizedBox(height: 12),
                      Text(
                        '验证失败 $_failedAttempts 次',
                        style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
                      ),
                    ],
                    SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _showScreenLock,
                      icon: Icon(Icons.lock_open),
                      label: Text('点击解锁'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF4A90E2),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    if (_showEmergencyUnlock) ...[
                      SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _emergencyUnlock,
                        icon: Icon(Icons.lock_open, color: Colors.orangeAccent),
                        label: Text(
                          '紧急解锁',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '连续验证失败5次后可使用紧急解锁',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyConsentScreen extends StatelessWidget {
  final VoidCallback onAgree;

  const _PolicyConsentScreen({required this.onAgree});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Spacer(flex: 2),
                Icon(Icons.auto_stories, size: 80, color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'AI人生记录器',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  '记录生活点滴，AI智能打标签',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Spacer(flex: 1),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('隐私保护说明', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. 您的数据存储在设备本地，我们不会上传至服务器\n'
                        '2. AI标签和报告功能会将文字发送至DeepSeek服务\n'
                        '3. 语音输入功能会将语音发送至讯飞服务\n'
                        '4. 您可以随时导出或删除全部数据',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.8),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('请阅读', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
                        },
                        child: Text('《隐私政策》', style: TextStyle(fontSize: 12, color: Color(0xFF64B5F6), decoration: TextDecoration.underline)),
                      ),
                      Text('和', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UserAgreementPage()));
                        },
                        child: Text('《用户协议》', style: TextStyle(fontSize: 12, color: Color(0xFF64B5F6), decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onAgree,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: Text('同意并继续', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text('不同意并退出', style: TextStyle(fontSize: 13, color: Colors.white54)),
                ),
                Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
