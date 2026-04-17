import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderService _reminderService = ReminderService.instance;
  bool _reminderEnabled = false;
  int _hour = 20;
  int _minute = 0;
  bool _isLoading = true;

  static const Color _bluePrimary = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    await _reminderService.loadSettings();
    if (mounted) {
      setState(() {
        _reminderEnabled = _reminderService.enabled;
        _hour = _reminderService.hour;
        _minute = _reminderService.minute;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('每日提醒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _bluePrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReminderCard(),
                  SizedBox(height: 24),
                  _buildTimeSelector(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bluePrimary, _bluePrimary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, size: 48, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('记录生活点滴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('每天固定时间提醒你记录今天的心情', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(bool isDark) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('启用每日提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
            subtitle: Text(
              _reminderEnabled ? '每天 ${_formatTime(_hour, _minute)} 提醒' : '未启用',
              style: TextStyle(fontSize: 12, color: subtitleColor),
            ),
            value: _reminderEnabled,
            activeColor: _bluePrimary,
            onChanged: _onToggleReminder,
          ),
          if (_reminderEnabled) ...[
            Divider(height: 1, color: theme.dividerColor),
            ListTile(
              title: Text('提醒时间', style: TextStyle(fontSize: 16, color: textColor)),
              subtitle: Text(
                _formatTime(_hour, _minute),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _bluePrimary),
              ),
              trailing: Icon(Icons.access_time, color: subtitleColor),
              onTap: _selectTime,
            ),
            Divider(height: 1, color: theme.dividerColor),
            ListTile(
              title: Text('诊断与修复', style: TextStyle(fontSize: 16, color: textColor)),
              subtitle: Text(
                '检查推送状态，修复推送问题',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              trailing: Icon(Icons.build, color: Colors.orange),
              onTap: _diagnoseAndFix,
            ),
            Divider(height: 1, color: theme.dividerColor),
            ListTile(
              title: Text('电池优化', style: TextStyle(fontSize: 16, color: textColor)),
              subtitle: Text(
                '关闭电池优化可防止推送被系统杀死',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              trailing: Icon(Icons.battery_std, color: Colors.teal),
              onTap: _showBatteryOptimizationDialog,
            ),
          ],
        ],
      ),
    );
  }

  void _onToggleReminder(bool value) {
    setState(() {
      _reminderEnabled = value;
    });

    _reminderService.setEnabled(value).then((success) {
      if (!mounted) return;
      if (success) {
        setState(() {
          _hour = _reminderService.hour;
          _minute = _reminderService.minute;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '提醒已启用' : '提醒已关闭'),
            backgroundColor: value ? Colors.green : _bluePrimary,
          ),
        );
      } else {
        setState(() {
          _reminderEnabled = false;
        });
        _showPermissionDeniedDialog();
      }
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _reminderEnabled = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败，请重试'), backgroundColor: Colors.red),
      );
    });
  }

  Future<void> _showPermissionDeniedDialog() async {
    final isPermanentlyDenied = await _reminderService.isNotificationPermissionPermanentlyDenied();
    if (!mounted) return;

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_off, color: _bluePrimary, size: 24),
            SizedBox(width: 8),
            Text('通知权限未开启', style: TextStyle(color: theme.colorScheme.onSurface)),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          isPermanentlyDenied
              ? '通知权限已被禁止，需要前往系统设置中手动开启通知权限，才能使用每日提醒功能。'
              : '需要通知权限才能启用每日提醒，请允许通知权限。',
          style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              if (isPermanentlyDenied) {
                await _reminderService.openNotificationSettings();
              } else {
                final granted = await _reminderService.requestNotificationPermission();
                if (granted && mounted) {
                  final success = await _reminderService.setEnabled(true);
                  if (success && mounted) {
                    setState(() {
                      _reminderEnabled = true;
                      _hour = _reminderService.hour;
                      _minute = _reminderService.minute;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('提醒已启用'), backgroundColor: Colors.green),
                    );
                  }
                }
              }
            },
            icon: Icon(isPermanentlyDenied ? Icons.settings : Icons.notifications_active, size: 18),
            label: Text(isPermanentlyDenied ? '去设置' : '允许'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _bluePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: _bluePrimary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await _reminderService.setTime(picked.hour, picked.minute);
      if (mounted) {
        setState(() {
          _hour = picked.hour;
          _minute = picked.minute;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提醒时间已设置为 ${_formatTime(picked.hour, picked.minute)}'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _showBatteryOptimizationDialog() async {
    if (!mounted) return;

    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.battery_std, color: _bluePrimary),
            SizedBox(width: 8),
            Text('电池优化设置', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text(
          '关闭电池优化可以防止系统在后台杀死推送服务，确保每日提醒正常触发。\n\n'
          '点击"去设置"后，请选择"允许"或"不优化"选项。',
          style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: textColor)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _reminderService.requestIgnoreBatteryOptimizations();
            },
            icon: Icon(Icons.open_in_new, size: 18),
            label: Text('去设置'),
            style: ElevatedButton.styleFrom(backgroundColor: _bluePrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _diagnoseAndFix() async {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.build, color: _bluePrimary),
            SizedBox(width: 8),
            Text('诊断推送问题', style: TextStyle(color: textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在检查推送状态...', style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );

    // Get debug info
    final debugInfo = await _reminderService.getDebugInfo();
    final status = await _reminderService.getNotificationStatus();

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Show detailed diagnostic info
    String diagnosis = '';
    String advice = '';

    if (!status['permission']) {
      diagnosis += '❌ 通知权限未开启\n';
      advice += '请前往系统设置开启通知权限\n';
    } else {
      diagnosis += '✅ 通知权限正常\n';
    }

    if (!status['canExactAlarm']) {
      diagnosis += '❌ 精确闹钟权限未开启\n';
      advice += '请前往系统设置允许精确闹钟\n';
    } else {
      diagnosis += '✅ 精确闹钟权限正常\n';
    }

    if (!status['scheduled']) {
      diagnosis += '❌ 通知未调度\n';
      advice += '将尝试重新调度通知\n';
    } else {
      diagnosis += '✅ 通知已调度\n';
    }

    // 检查电池优化状态
    final isIgnoringBattery = await _reminderService.isIgnoringBatteryOptimizations();
    if (!isIgnoringBattery) {
      diagnosis += '❌ 电池优化未关闭（推送可能被系统杀死）\n';
      advice += '建议前往"电池优化"设置，关闭电池优化\n';
    } else {
      diagnosis += '✅ 电池优化已关闭\n';
    }

    // Try to fix
    bool fixSuccess = false;
    if (!status['scheduled'] || !status['permission'] || !status['canExactAlarm']) {
      fixSuccess = await _reminderService.forceReschedule();
      if (fixSuccess) {
        advice += '\n✅ 已尝试修复，请观察下次推送是否成功';
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: _bluePrimary),
              SizedBox(width: 8),
              Text('诊断结果'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('状态检查：', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                SizedBox(height: 4),
                Text(diagnosis, style: TextStyle(fontSize: 13, color: textColor)),
                SizedBox(height: 8),
                if (advice.isNotEmpty) ...[
                  Text('建议操作：', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  SizedBox(height: 4),
                  Text(advice, style: TextStyle(fontSize: 13, color: textColor)),
                ],
                SizedBox(height: 8),
                Text('调试信息：', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(debugInfo, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: textColor)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('关闭'),
            ),
            if (!status['permission'])
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _reminderService.openNotificationSettings();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _bluePrimary),
                child: Text('开启权限'),
              ),
          ],
        ),
      );
    }
  }
}
