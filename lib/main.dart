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

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final lockService = LockService.instance;
    final success = await lockService.authenticate();

    setState(() => _isAuthenticating = false);

    if (success) {
      widget.onUnlock();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u9A8C\u8BC1\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
          child: Center(
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
                  label: Text(_isAuthenticating ? '\u9A8C\u8BC1\u4E2D...' : '\u70B9\u51FB\u9A8C\u8BC1'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF4A90E2),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
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
