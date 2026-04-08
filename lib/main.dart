import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _lockEnabled) {
      setState(() => _isLocked = true);
    }
  }

  void _checkLock() async {
    final lockService = LockService.instance;
    _lockEnabled = lockService.lockEnabled;
    _isLocked = _lockEnabled;
  }

  void _unlock() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI人生记录器',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: widget.themeService.themeMode,
      home: _isLocked && _lockEnabled
          ? LockScreen(onUnlock: _unlock)
          : const HomePage(),
    );
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
          SnackBar(content: Text('验证失败，请重试'), backgroundColor: Colors.red),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
