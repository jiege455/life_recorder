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

  @override
  void initState() { super.initState(); _initState(); }
  Future<void> _initState() async { await _reminderService.loadSettings(); if (mounted) { setState(() { _reminderEnabled = _reminderService.enabled; _hour = _reminderService.hour; _minute = _reminderService.minute; _isLoading = false; }); } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text('每日提醒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: primaryColor, elevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildReminderCard(), SizedBox(height: 24), _buildTimeSelector(primaryColor)])),
    );
  }

  Widget _buildReminderCard() {
    return Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(Icons.notifications_active, size: 48, color: Colors.white), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('记录生活点滴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), SizedBox(height: 4), Text('每天固定时间提醒你记录今天的心情', style: TextStyle(fontSize: 13, color: Colors.white70))]))]));
  }

  Widget _buildTimeSelector(Color primaryColor) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    return Container(decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]), child: Column(children: [SwitchListTile(title: Text('启用每日提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)), subtitle: Text(_reminderEnabled ? '每天 ${_formatTime(_hour, _minute)} 提醒' : '未启用', style: TextStyle(fontSize: 12, color: subtitleColor)), value: _reminderEnabled, activeColor: primaryColor, onChanged: _onToggleReminder), if (_reminderEnabled) ...[Divider(height: 1, color: theme.dividerColor), ListTile(title: Text('提醒时间', style: TextStyle(fontSize: 16, color: textColor)), subtitle: Text(_formatTime(_hour, _minute), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)), trailing: Icon(Icons.access_time, color: subtitleColor), onTap: _selectTime)]]));
  }

  void _onToggleReminder(bool value) {
    setState(() { _reminderEnabled = value; });
    _reminderService.setEnabled(value).then((success) {
      if (!mounted) return;
      if (success) { setState(() { _hour = _reminderService.hour; _minute = _reminderService.minute; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? '提醒已启用' : '提醒已关闭'), backgroundColor: value ? Colors.green : Colors.orange)); }
      else { setState(() { _reminderEnabled = false; }); _showPermissionDeniedDialog(); }
    }).catchError((e) { if (!mounted) return; setState(() { _reminderEnabled = !value; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败，请重试'), backgroundColor: Colors.red)); });
  }

  Future<void> _showPermissionDeniedDialog() async {
    final isPermanentlyDenied = await _reminderService.isNotificationPermissionPermanentlyDenied();
    if (!mounted) return;
    final theme = Theme.of(context);
    showDialog(context: context, builder: (context) => AlertDialog(title: Row(children: [Icon(Icons.notifications_off, color: Colors.orange, size: 24), SizedBox(width: 8), Text('通知权限未开启')]), backgroundColor: theme.colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), content: Text(isPermanentlyDenied ? '通知权限已被禁止，需要前往系统设置中手动开启通知权限，才能使用每日提醒功能。' : '需要通知权限才能启用每日提醒，请允许通知权限。', style: TextStyle(fontSize: 14, height: 1.6)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')), ElevatedButton.icon(onPressed: () async { Navigator.pop(context); if (isPermanentlyDenied) { await _reminderService.openNotificationSettings(); } else { final granted = await _reminderService.requestNotificationPermission(); if (granted && mounted) { final success = await _reminderService.setEnabled(true); if (success && mounted) { setState(() { _reminderEnabled = true; _hour = _reminderService.hour; _minute = _reminderService.minute; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提醒已启用'), backgroundColor: Colors.green)); } } } }, icon: Icon(isPermanentlyDenied ? Icons.settings : Icons.notifications_active, size: 18), label: Text(isPermanentlyDenied ? '去设置' : '允许'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4A90E2), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))]));
  }

  String _formatTime(int hour, int minute) => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _hour, minute: _minute), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Color(0xFF4A90E2))), child: child!));
    if (picked != null) { await _reminderService.setTime(picked.hour, picked.minute); if (mounted) { setState(() { _hour = picked.hour; _minute = picked.minute; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提醒时间已设置为 ${_formatTime(picked.hour, picked.minute)}'), backgroundColor: Colors.green)); } }
  }
}
