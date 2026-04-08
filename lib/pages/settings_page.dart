import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../services/lock_service.dart';
import '../services/reminder_service.dart';
import '../services/tag_service.dart';
import '../services/backup_service.dart';
import '../database/database_helper.dart';
import 'tag_manager_page.dart';
import 'lock_settings_page.dart';
import 'reminder_page.dart';
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
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('\u8BBE\u7F6E',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            _buildSectionTitle('\u5916\u89C2'),
            _buildThemeSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('\u6807\u7B7E\u7BA1\u7406'),
            _buildTagManagerSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('\u6570\u636E\u7BA1\u7406'),
            _buildBackupSetting(),
            _buildRestoreSetting(),
            _buildClearDataSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('\u9690\u79C1\u4E0E\u5B89\u5168'),
            _buildLockSetting(),
            _buildPrivacyPolicySetting(),
            _buildUserAgreementSetting(),
            SizedBox(height: 24),
            _buildSectionTitle('\u63D0\u9192'),
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
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildThemeSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.brightness_6, color: Color(0xFF4A90E2)),
            title: Text('\u6DF1\u8272\u6A21\u5F0F', style: TextStyle(fontSize: 15)),
            subtitle: Text(_getThemeModeText(),
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
        return '\u6D45\u8272\u6A21\u5F0F';
      case ThemeMode.dark:
        return '\u6DF1\u8272\u6A21\u5F0F';
      case ThemeMode.system:
        return '\u8DDF\u968F\u7CFB\u7EDF';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\u9009\u62E9\u4E3B\u9898'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('\u8DDF\u968F\u7CFB\u7EDF', ThemeMode.system),
            _buildThemeOption('\u6D45\u8272\u6A21\u5F0F', ThemeMode.light),
            _buildThemeOption('\u6DF1\u8272\u6A21\u5F0F', ThemeMode.dark),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.label, color: Color(0xFF4A90E2)),
        title: Text('\u81EA\u5B9A\u4E49\u6807\u7B7E', style: TextStyle(fontSize: 15)),
        subtitle: Text('\u7BA1\u7406\u5E38\u7528\u6807\u7B7E',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => TagManagerPage()));
        },
      ),
    );
  }

  Widget _buildBackupSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.backup, color: Color(0xFF4A90E2)),
        title: Text('\u5BFC\u51FA\u6570\u636E', style: TextStyle(fontSize: 15)),
        subtitle:
            Text('\u5C06\u8BB0\u5F55\u5BFC\u51FA\u4E3AJSON\u6587\u4EF6',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: _isExporting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: _isExporting ? null : _exportData,
      ),
    );
  }

  Widget _buildRestoreSetting() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.restore, color: Color(0xFF4A90E2)),
        title: Text('\u5BFC\u5165\u6570\u636E', style: TextStyle(fontSize: 15)),
        subtitle:
            Text('\u4ECEJSON\u6587\u4EF6\u6062\u590D\u8BB0\u5F55',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: _isImporting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: _isImporting ? null : _importData,
      ),
    );
  }

  Widget _buildLockSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.lock, color: Color(0xFF4A90E2)),
        title: Text('\u9690\u79C1\u9501', style: TextStyle(fontSize: 15)),
        subtitle: Text(_lockEnabled ? '\u5DF2\u542F\u7528' : '\u672A\u542F\u7528',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LockSettingsPage()));
          _loadSettings();
        },
      ),
    );
  }

  Widget _buildReminderSetting() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.notifications, color: Color(0xFF4A90E2)),
        title: Text('\u6BCF\u65E5\u63D0\u9192', style: TextStyle(fontSize: 15)),
        subtitle: Text(_reminderEnabled ? '\u5DF2\u542F\u7528' : '\u672A\u542F\u7528',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => ReminderPage()));
          _loadSettings();
        },
      ),
    );
  }

  Widget _buildClearDataSetting() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: Colors.red),
        title: Text('\u6E05\u9664\u6240\u6709\u6570\u636E', style: TextStyle(fontSize: 15, color: Colors.red)),
        subtitle: Text('\u5220\u9664\u5168\u90E8\u8BB0\u5F55\uFF0C\u6B64\u64CD\u4F5C\u4E0D\u53EF\u6062\u590D',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: _clearAllData,
      ),
    );
  }

  Widget _buildPrivacyPolicySetting() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.privacy_tip, color: Color(0xFF4A90E2)),
        title: Text('\u9690\u79C1\u653F\u7B56', style: TextStyle(fontSize: 15)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
        },
      ),
    );
  }

  Widget _buildUserAgreementSetting() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.description, color: Color(0xFF4A90E2)),
        title: Text('\u7528\u6237\u534F\u8BAE', style: TextStyle(fontSize: 15)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserAgreementPage()));
        },
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\u786E\u8BA4\u6E05\u9664\u6240\u6709\u6570\u636E'),
        content: Text('\u6B64\u64CD\u4F5C\u5C06\u6C38\u4E45\u5220\u9664\u6240\u6709\u8BB0\u5F55\u6570\u636E\uFF0C\u4E14\u4E0D\u53EF\u6062\u590D\u3002\u5EFA\u8BAE\u60A8\u5148\u5BFC\u51FA\u6570\u636E\u5907\u4EFD\u3002\u786E\u5B9A\u8981\u7EE7\u7EED\u5417\uFF1F'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('\u53D6\u6D88'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('\u786E\u8BA4\u6E05\u9664', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteAllRecords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('\u6240\u6709\u6570\u636E\u5DF2\u6E05\u9664'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('\u6E05\u9664\u6570\u636E\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final path = await BackupService.instance.exportData();
      if (path == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('\u5BFC\u51FA\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5'),
              backgroundColor: Colors.red),
        );
      } else if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('\u6570\u636E\u5BFC\u51FA\u6210\u529F\uFF01'),
              backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      final backupInfo = await BackupService.instance.readBackupFile();
      if (backupInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('\u672A\u9009\u62E9\u6587\u4EF6\u6216\u6587\u4EF6\u683C\u5F0F\u9519\u8BEF'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('\u786E\u8BA4\u5BFC\u5165'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u5373\u5C06\u5BFC\u5165\u4EE5\u4E0B\u5907\u4EFD\u6570\u636E\uFF1A',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              _buildInfoRow(
                  '\u8BB0\u5F55\u6570\u91CF', '${backupInfo['recordCount']}\u6761'),
              _buildInfoRow(
                  '\u5907\u4EFD\u65F6\u95F4', backupInfo['exportTime'].toString()),
              _buildInfoRow('\u7248\u672C', backupInfo['version'].toString()),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\u5BFC\u5165\u5C06\u66FF\u6362\u5F53\u524D\u6240\u6709\u6570\u636E\uFF0C\u8BF7\u786E\u4FDD\u5DF2\u5907\u4EFD',
                        style:
                            TextStyle(fontSize: 13, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('\u53D6\u6D88'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('\u786E\u8BA4\u5BFC\u5165'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A90E2)),
                  SizedBox(height: 16),
                  Text('\u6B63\u5728\u5BFC\u5165\u6570\u636E...',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );

      final success =
          await BackupService.instance.importData(backupInfo['records']);

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '\u6570\u636E\u5BFC\u5165\u6210\u529F\uFF01\u5171\u5BFC\u5165${backupInfo['recordCount']}\u6761\u8BB0\u5F55'),
                backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('\u5BFC\u5165\u5931\u8D25\uFF0C\u8BF7\u68C0\u67E5\u5907\u4EFD\u6587\u4EF6\u683C\u5F0F'),
                backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          SizedBox(width: 12),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
