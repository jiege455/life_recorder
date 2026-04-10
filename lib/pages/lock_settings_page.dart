import 'package:flutter/material.dart';
import '../services/lock_service.dart';

class LockSettingsPage extends StatefulWidget {
  const LockSettingsPage({super.key});

  @override
  State<LockSettingsPage> createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  bool _lockEnabled = false;
  bool _hasPinSet = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockService = LockService.instance;
    setState(() {
      _lockEnabled = lockService.lockEnabled;
      _hasPinSet = false;
    });

    final hasPin = await lockService.hasPinSet();
    if (mounted) {
      setState(() {
        _hasPinSet = hasPin;
      });
    }
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
              _buildPinCard(context, cardColor, primaryColor),
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
          Text('开启后，每次启动应用都需要输入 PIN 码或使用生物识别验证', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
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

  Widget _buildPinCard(BuildContext context, Color cardColor, Color primaryColor) {
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
              Icon(Icons.pin, size: 20, color: primaryColor),
              SizedBox(width: 8),
              Text('PIN 码管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 16),
          Text(_hasPinSet ? '已设置 PIN 码' : '未设置 PIN 码', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          SizedBox(height: 12),
          if (_hasPinSet)
            ElevatedButton.icon(
              onPressed: () => _resetPin(),
              icon: Icon(Icons.refresh, size: 18),
              label: Text('重置 PIN 码'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _setupPin(),
              icon: Icon(Icons.add, size: 18),
              label: Text('设置 PIN 码'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
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
              Text('功能说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoItem('PIN 码验证', '4 位数字密码，安全键盘输入'),
          _buildInfoItem('生物识别', '支持指纹、面部识别'),
          _buildInfoItem('忘记密码', '连续失败 5 次可紧急解锁'),
          _buildInfoItem('安全性', 'PIN 码 SHA-256 加密存储'),
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
    await LockService.instance.setLockEnabled(value);
    setState(() {
      _lockEnabled = value;
      if (!value) _hasPinSet = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? '隐私锁已开启' : '隐私锁已关闭')),
    );

    if (value && !_hasPinSet) {
      Future.delayed(Duration(seconds: 1), () => _setupPin());
    }
  }

  void _setupPin() {
    LockService.instance.showCreatePinScreen(
      context,
      onConfirmed: () {
        _loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN 码设置成功')),
        );
      },
    );
  }

  void _resetPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重置 PIN 码'),
        content: Text('确定要重置 PIN 码吗？需要重新设置新的 PIN 码。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LockService.instance.disableLock();
      await LockService.instance.setLockEnabled(true);

      setState(() {
        _hasPinSet = false;
      });

      Future.delayed(Duration(seconds: 1), () => _setupPin());
    }
  }
}
