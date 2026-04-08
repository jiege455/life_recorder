import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/lock_service.dart';
import '../services/reminder_service.dart';
import '../services/tag_service.dart';
import '../services/backup_service.dart';
import 'tag_manager_page.dart';
import 'lock_settings_page.dart';
import 'reminder_page.dart';

class SettingsPage extends StatefulWidget {
  final ThemeService themeService;

  const SettingsPage({super.key, required this.themeService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _lockEnabled = false;
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _themeMode = widget.themeService.themeMode;
      _lockEnabled = LockService.instance.lockEnabled;
      _reminderEnabled = ReminderService.instance.enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('设置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('外观'),
            _buildThemeSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('标签管理'),
            _buildTagManagerSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('数据管理'),
            _buildBackupSetting(),
            _buildRestoreSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('隐私与安全'),
            _buildLockSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('提醒'),
            _buildReminderSetting(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildThemeSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.brightness_6, color: Color(0xFF4A90E2)),
            title: Text('深色模式', style: TextStyle(fontSize: 15)),
            subtitle: Text(_getThemeModeText(), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: _showThemeDialog,
          ),
        ],
      ),
    );
  }

  String _getThemeModeText() {
    switch (_themeMode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择主题'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('跟随系统', ThemeMode.system),
            _buildThemeOption('浅色模式', ThemeMode.light),
            _buildThemeOption('深色模式', ThemeMode.dark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String text, ThemeMode mode) {
    return RadioListTile<ThemeMode>(
      title: Text(text),
      value: mode,
      groupValue: _themeMode,
      activeColor: Color(0xFF4A90E2),
      onChanged: (value) async {
        await widget.themeService.setThemeMode(value!);
        setState(() => _themeMode = value);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Widget _buildTagManagerSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(Icons.label, color: Color(0xFF4A90E2)),
        title: Text('自定义标签', style: TextStyle(fontSize: 15)),
        subtitle: Text('管理常用标签', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => TagManagerPage()));
        },
      ),
    );
  }

  Widget _buildBackupSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(Icons.backup, color: Color(0xFF4A90E2)),
        title: Text('导出数据', style: TextStyle(fontSize: 15)),
        subtitle: Text('将记录导出为JSON文件', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: _exportData,
      ),
    );
  }

  Widget _buildRestoreSetting() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(Icons.restore, color: Color(0xFF4A90E2)),
        title: Text('导入数据', style: TextStyle(fontSize: 15)),
        subtitle: Text('从JSON文件恢复记录', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: _importData,
      ),
    );
  }

  Widget _buildLockSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(Icons.lock, color: Color(0xFF4A90E2)),
        title: Text('隐私锁', style: TextStyle(fontSize: 15)),
        subtitle: Text(_lockEnabled ? '已启用' : '未启用', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LockSettingsPage()));
        },
      ),
    );
  }

  Widget _buildReminderSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(Icons.notifications, color: Color(0xFF4A90E2)),
        title: Text('每日提醒', style: TextStyle(fontSize: 15)),
        subtitle: Text(_reminderEnabled ? '已启用' : '未启用', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderPage()));
        },
      ),
    );
  }

  Future<void> _exportData() async {
    final path = await BackupService.instance.exportData();
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据已导出到: $path'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importData() async {
    final success = await BackupService.instance.importData();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据导入成功'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败或已取消'), backgroundColor: Colors.orange),
      );
    }
  }
}
