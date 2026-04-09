import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lock_service.dart';

class LockSettingsPage extends StatefulWidget {
  const LockSettingsPage({super.key});

  @override
  State<LockSettingsPage> createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  bool _lockEnabled = false;
  String? _currentPassword;
  String? _newPassword;
  String? _confirmPassword;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockService = LockService.instance;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockEnabled = prefs.getBool('lock_enabled') ?? false;
      _currentPassword = prefs.getString('lock_password');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('隐私锁设置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLockToggleCard(context, cardColor, primaryColor),
            SizedBox(height: 16),
            if (_lockEnabled) ...[
              _buildPasswordCard(context, cardColor, primaryColor),
              SizedBox(height: 16),
              _buildInfoCard(context, cardColor, primaryColor),
            ],
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLockToggleCard(BuildContext context, Color cardColor, Color primaryColor) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, size: 20, color: primaryColor),
              SizedBox(width: 8),
              Text('隐私锁开关', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          Text('开启后，每次启动应用都需要输入密码才能访问', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          SizedBox(height: 12),
          SwitchListTile(
            title: Text(_lockEnabled ? '已开启' : '已关闭', style: TextStyle(fontSize: 15)),
            subtitle: Text(_lockEnabled ? '应用已保护' : '点击开启保护', style: TextStyle(fontSize: 13)),
            value: _lockEnabled,
            onChanged: (value) => _toggleLock(value),
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context, Color cardColor, Color primaryColor) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.password, size: 20, color: primaryColor),
              SizedBox(width: 8),
              Text('密码管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 16),
          if (_isChangingPassword) ...[
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '新密码',
                hintText: '请输入 4-8 位数字密码',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              onChanged: (value) => _newPassword = value,
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '确认密码',
                hintText: '请再次输入密码',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              onChanged: (value) => _confirmPassword = value,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isChangingPassword = false;
                      _newPassword = null;
                      _confirmPassword = null;
                    });
                  },
                  child: Text('取消'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: Text(_currentPassword == null ? '设置密码' : '修改密码'),
                ),
              ],
            ),
          ] else ...[
            Text(_currentPassword != null ? '已设置密码' : '未设置密码', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isChangingPassword = true;
                });
              },
              icon: Icon(Icons.edit, size: 18),
              label: Text(_currentPassword != null ? '修改密码' : '设置密码'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Color cardColor, Color primaryColor) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: primaryColor),
              SizedBox(width: 8),
              Text('使用说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoItem('密码长度', '4-8 位数字'),
          _buildInfoItem('密码保护', '密码加密存储，请放心使用'),
          _buildInfoItem('忘记密码', '如忘记密码，需清除应用数据'),
          _buildInfoItem('安全建议', '建议设置不易被猜到的密码'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                children: [
                  TextSpan(text: '$label：', style: TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_enabled', value);
    
    if (value && _currentPassword == null) {
      setState(() {
        _isChangingPassword = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先设置密码')),
      );
    } else {
      setState(() {
        _lockEnabled = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? '隐私锁已开启' : '隐私锁已关闭')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPassword == null || _newPassword!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入密码')),
      );
      return;
    }

    if (_newPassword!.length < 4 || _newPassword!.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('密码长度必须在 4-8 位之间')),
      );
      return;
    }

    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('两次输入的密码不一致')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lock_password', _newPassword!);
    
    setState(() {
      _currentPassword = _newPassword;
      _isChangingPassword = false;
      _newPassword = null;
      _confirmPassword = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_currentPassword != null && _currentPassword!.isNotEmpty ? '密码修改成功' : '密码设置成功')),
    );
  }
}
