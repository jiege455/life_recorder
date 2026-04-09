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
            Text('\u901A\u77E5\u6743\u9650\u5DF2\u5173\u95ED'),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          '\u60A8\u4E4B\u524D\u5DF2\u542F\u7528\u6BCF\u65E5\u63D0\u9192\u529F\u80FD\uFF0C\u4F46\u901A\u77E5\u6743\u9650\u5DF2\u88AB\u5173\u95ED\u3002\u6BCF\u65E5\u63D0\u9192\u5C06\u65E0\u6CD5\u6B63\u5E38\u5DE5\u4F5C\uFF0C\u8BF7\u524D\u5F80\u7CFB\u7EDF\u8BBE\u7F6E\u91CD\u65B0\u5F00\u542F\u901A\u77E5\u6743\u9650\u3002',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('\u6682\u4E0D\u8BBE\u7F6E'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ReminderService.instance.openNotificationSettings();
            },
            icon: Icon(Icons.settings, size: 18),
            label: Text('\u53BB\u8BBE\u7F6E'),
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
      useBlur: false,
      title: Text('\u8F93\u5165 PIN \u7801\u89E3\u9501'),
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
        title: Text('\u7D27\u6025\u89E3\u9501'),
        content: Text('\u8FD9\u5C06\u5173\u95ED\u9690\u79C1\u9501\u529F\u80FD\u5E76\u8FDB\u5165\u5E94\u7528\u3002\u60A8\u53EF\u4EE5\u5728\u8BBE\u7F6E\u4E2D\u91CD\u65B0\u542F\u7528\u9690\u79C1\u9501\u3002'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('\u53D6\u6D88'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('\u786E\u8BA4\u89E3\u9501', style: TextStyle(color: Colors.white)),
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
                      'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\u5DF2\u542F\u7528\u9690\u79C1\u4FDD\u62A4',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    if (_failedAttempts > 0) ...[
                      SizedBox(height: 12),
                      Text(
                        '\u9A8C\u8BC1\u5931\u8D25 $_failedAttempts \u6B21',
                        style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
                      ),
                    ],
                    SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _showScreenLock,
                      icon: Icon(Icons.lock_open),
                      label: Text('\u70B9\u51FB\u89E3\u9501'),
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
                          '\u7D27\u6025\u89E3\u9501',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '\u8FDE\u7EED\u9A8C\u8BC1\u5931\u8D255\u6B21\u540E\u53EF\u4F7F\u7528\u7D27\u6025\u89E3\u9501',
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
                  'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  '\u8BB0\u5F55\u751F\u6D3B\u70B9\u6EF4\uFF0CAI\u667A\u80FD\u6253\u6807\u7B7E',
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
                          Text('\u9690\u79C1\u4FDD\u62A4\u8BF4\u660E', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. \u60A8\u7684\u6570\u636E\u5B58\u50A8\u5728\u8BBE\u5907\u672C\u5730\uFF0C\u6211\u4EEC\u4E0D\u4F1A\u4E0A\u4F20\u81F3\u670D\u52A1\u5668\n'
                        '2. AI\u6807\u7B7E\u548C\u62A5\u544A\u529F\u80FD\u4F1A\u5C06\u6587\u5B57\u53D1\u9001\u81F3DeepSeek\u670D\u52A1\n'
                        '3. \u8BED\u97F3\u8F93\u5165\u529F\u80FD\u4F1A\u5C06\u8BED\u97F3\u53D1\u9001\u81F3\u8BAF\u98DE\u670D\u52A1\n'
                        '4. \u60A8\u53EF\u4EE5\u968F\u65F6\u5BFC\u51FA\u6216\u5220\u9664\u5168\u90E8\u6570\u636E',
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
                      Text('\u8BF7\u9605\u8BFB', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
                        },
                        child: Text('\u300A\u9690\u79C1\u653F\u7B56\u300B', style: TextStyle(fontSize: 12, color: Color(0xFF64B5F6), decoration: TextDecoration.underline)),
                      ),
                      Text('\u548C', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UserAgreementPage()));
                        },
                        child: Text('\u300A\u7528\u6237\u534F\u8BAE\u300B', style: TextStyle(fontSize: 12, color: Color(0xFF64B5F6), decoration: TextDecoration.underline)),
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
                    child: Text('\u540C\u610F\u5E76\u7EE7\u7EED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text('\u4E0D\u540C\u610F\u5E76\u9000\u51FA', style: TextStyle(fontSize: 13, color: Colors.white54)),
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
