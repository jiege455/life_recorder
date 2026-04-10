import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/user_agreement_page.dart';
import 'services/theme_service.dart';
import 'services/lock_service.dart';
import 'services/reminder_service.dart';
import 'services/tag_service.dart';
import 'config/api_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final themeService = await ThemeService.getInstance();
  await themeService.loadThemeMode();
  await ApiConfig.loadConfig();
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
    final primaryColor = theme.colorScheme.primary;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_off, color: primaryColor, size: 24),
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
              backgroundColor: primaryColor,
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
          title: 'AI 人生记录器',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: widget.themeService.themeMode,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('zh', 'CN'),
            const Locale('en', 'US'),
          ],
          locale: const Locale('zh', 'CN'),
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
  String _inputPin = '';
  String _correctPin = '';
  bool _isLoading = true;
  int _failedAttempts = 0;
  bool _showEmergencyUnlock = false;
  bool _isWrong = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final pin = await LockService.instance.getSavedPin();
    if (!mounted) return;
    if (pin == null || pin.isEmpty) {
      // 如果没有设置 PIN 码，直接解锁
      LockService.instance.unlock();
      widget.onUnlock();
      return;
    }
    setState(() {
      _correctPin = pin;
      _isLoading = false;
    });
  }

  void _onDigitPressed(String digit) {
    if (_inputPin.length >= 4) return;
    setState(() {
      _inputPin += digit;
      _isWrong = false;
    });
    if (_inputPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_inputPin.isEmpty) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      _isWrong = false;
    });
  }

  void _verifyPin() {
    // 严格验证 PIN 码
    if (_inputPin == _correctPin) {
      // 验证成功
      LockService.instance.unlock();
      widget.onUnlock();
    } else {
      // 验证失败
      setState(() {
        _failedAttempts++;
        _isWrong = true;
        _inputPin = '';
        
        // 连续失败 5 次后显示紧急解锁
        if (_failedAttempts >= 5) {
          _showEmergencyUnlock = true;
        }
      });
      
      // 震动反馈
      HapticFeedback.vibrate();
    }
  }

  Future<void> _onBiometricPressed() async {
    final success = await LockService.instance.authenticateWithBiometrics();
    if (success && mounted) {
      LockService.instance.unlock();
      widget.onUnlock();
    }
  }

  Future<void> _emergencyUnlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('紧急解锁'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('连续验证失败，需要关闭隐私锁才能进入应用。', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('⚠️ 注意：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('这将永久关闭隐私锁功能，您需要重新在设置中开启并设置新的 PIN 码。', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: Text('确认关闭隐私锁', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 关闭隐私锁
      await LockService.instance.disableLock();
      // 解锁并进入应用
      LockService.instance.unlock();
      widget.onUnlock();
      
      // 显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('隐私锁已关闭，请在设置中重新开启'),
            backgroundColor: Colors.red[700],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A90E2), Color(0xFF16213E)],
            ),
          ),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

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
            child: Column(
              children: [
                SizedBox(height: 80),
                Icon(Icons.lock_outline, size: 60, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'AI人生记录器',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  '请输入 PIN 码解锁',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                if (_failedAttempts > 0) ...[
                  SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _isWrong ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: Text(
                      'PIN 码错误，已失败 $_failedAttempts 次',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent),
                    ),
                  ),
                ],
                SizedBox(height: 32),
                _buildPinDots(),
                SizedBox(height: 32),
                _buildNumPad(),
                SizedBox(height: 16),
                _buildBiometricButton(),
                if (_showEmergencyUnlock) ...[
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _emergencyUnlock,
                    icon: Icon(Icons.lock_open, color: Colors.redAccent, size: 20),
                    label: Text('紧急解锁', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ),
                  Text(
                    '连续验证失败 5 次后可使用紧急解锁',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _inputPin.length;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isWrong ? Colors.redAccent : (isFilled ? Colors.white : Colors.transparent),
            border: Border.all(
              color: _isWrong ? Colors.redAccent : Colors.white54,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumPad() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3']),
          SizedBox(height: 12),
          _buildNumRow(['4', '5', '6']),
          SizedBox(height: 12),
          _buildNumRow(['7', '8', '9']),
          SizedBox(height: 12),
          _buildNumRow(['', '0', 'del']),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        if (d == 'del') {
          return _buildDeleteButton();
        } else if (d.isEmpty) {
          return SizedBox(width: 72, height: 72);
        } else {
          return _buildDigitButton(d);
        }
      }).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.white.withOpacity(0.1),
        shape: CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onDigitPressed(digit),
          splashColor: Colors.white24,
          child: Center(
            child: Text(
              digit,
              style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w300),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _onDeletePressed,
          splashColor: Colors.white24,
          child: Center(
            child: Icon(Icons.backspace_outlined, color: Colors.white54, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox.shrink();
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
