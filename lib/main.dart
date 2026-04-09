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
  bool _isAuthenticating = false;
  int _failedAttempts = 0;
  bool _showEmergencyUnlock = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final lockService = LockService.instance;
    final success = await lockService.authenticate();

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      _failedAttempts = 0;
      widget.onUnlock();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        setState(() => _showEmergencyUnlock = true);
      }
    }
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
                      onPressed: _isAuthenticating ? null : _authenticate,
                      icon: _isAuthenticating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.fingerprint),
                      label: Text(_isAuthenticating ? '验证中...' : '点击验证'),
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
