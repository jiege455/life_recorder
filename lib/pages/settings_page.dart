import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../services/lock_service.dart';
import '../services/reminder_service.dart';
import '../services/tag_service.dart';
import '../services/backup_service.dart';
import '../config/api_config.dart';
import '../database/database_helper.dart';
import 'tag_manager_page.dart';
import 'lock_settings_page.dart';
import 'reminder_page.dart';
import 'api_config_page.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';

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
  bool _isExporting = false;
  bool _isImporting = false;

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
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('设置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('外观'),
            _buildThemeSetting(cardColor, primaryColor, isDark),
            SizedBox(height: 24),
            _buildSectionTitle('标签管理'),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.label, '自定义标签', '管理常用标签',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TagManagerPage())),
            ),
            SizedBox(height: 24),
            _buildSectionTitle('数据管理'),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.backup, '导出数据', '将记录导出为JSON文件',
              trailing: _isExporting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              onTap: _isExporting ? null : _exportData,
            ),
            SizedBox(height: 8),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.restore, '导入数据', '从JSON文件恢复记录',
              trailing: _isImporting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              onTap: _isImporting ? null : _importData,
            ),
            SizedBox(height: 8),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.delete_forever, '清除所有数据', '删除全部记录，此操作不可恢复',
              iconColor: Colors.red, titleColor: Colors.red, onTap: _clearAllData,
            ),
            SizedBox(height: 24),
            _buildSectionTitle('隐私与安全'),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.lock, '隐私锁', _lockEnabled ? '已启用' : '未启用',
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => LockSettingsPage())); _loadSettings(); },
            ),
            SizedBox(height: 8),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.privacy_tip, '隐私政策', null,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage())),
            ),
            SizedBox(height: 8),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.description, '用户协议', null,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserAgreementPage())),
            ),
            SizedBox(height: 24),
            _buildSectionTitle('提醒'),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.notifications, '每日提醒', _reminderEnabled ? '已启用' : '未启用',
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderPage())); _loadSettings(); },
            ),
            SizedBox(height: 24),
            _buildSectionTitle('API密钥配置'),
            _buildSettingCard(cardColor, isDark, primaryColor, Icons.vpn_key, 'API密钥配置', '配置语音识别和AI标签的API密钥',
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => ApiConfigPage())); _loadSettings(); },
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildSettingCard(Color cardColor, bool isDark, Color primaryColor,
      IconData icon, String title, String? subtitle,
      {Color? iconColor, Color? titleColor, Widget? trailing, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? primaryColor),
        title: Text(title, style: TextStyle(fontSize: 15, color: titleColor ?? textColor)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: subtitleColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSetting(Color cardColor, Color primaryColor, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.brightness_6, color: primaryColor),
            title: Text('深色模式', style: TextStyle(fontSize: 15)),
            subtitle: Text(_getThemeModeText(), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            onTap: _showThemeDialog,
          ),
        ],
      ),
    );
  }

  String _getThemeModeText() {
    switch (_themeMode) {
      case ThemeMode.light: return '浅色模式';
      case ThemeMode.dark: return '深色模式';
      case ThemeMode.system: return '跟随系统';
    }
  }

  void _showThemeDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择主题'),
        backgroundColor: theme.colorScheme.surface,
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

  Future<void> _clearAllData() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认清除所有数据'),
        backgroundColor: theme.colorScheme.surface,
        content: Text('此操作将永久删除所有记录数据，且不可恢复。建议您先导出数据备份。确定要继续吗？'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确认清除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteAllRecords();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('所有数据已清除'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('清除数据失败，请重试'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final path = await BackupService.instance.exportData();
      if (path == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败，请重试'), backgroundColor: Colors.red));
      } else if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('数据导出成功！'), backgroundColor: Colors.green));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      final backupInfo = await BackupService.instance.readBackupFile();
      if (backupInfo == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('未选择文件或文件格式错误'), backgroundColor: Colors.orange));
        return;
      }
      if (!mounted) return;
      final theme = Theme.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('确认导入'),
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('即将导入以下备份数据：', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              _buildInfoRow('记录数量', '${backupInfo['recordCount']}条'),
              _buildInfoRow('备份时间', backupInfo['exportTime'].toString()),
              _buildInfoRow('版本', backupInfo['version'].toString()),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [Icon(Icons.warning, color: Colors.orange, size: 20), SizedBox(width: 8), Expanded(child: Text('导入将替换当前所有数据，请确保已备份', style: TextStyle(fontSize: 13, color: theme.colorScheme.error)))]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A90E2), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('确认导入')),
          ],
        ),
      );
      if (confirm != true) return;
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Color(0xFF4A90E2)), SizedBox(height: 16), Text('正在导入数据...', style: TextStyle(fontSize: 14))])))));
      final success = await BackupService.instance.importData(backupInfo['records']);
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('数据导入成功！共导入${backupInfo['recordCount']}条记录'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败，请检查备份文件格式'), backgroundColor: Colors.red));
        }
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)), SizedBox(width: 12), Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface))]),
    );
  }
}
