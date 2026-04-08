import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderService _reminderService = ReminderService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _reminderService.loadSettings();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('每日提醒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
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
                  _buildTimeSelector(),
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
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
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
                Text(
                  '记录生活点滴',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  '每天固定时间提醒你记录今天的心情',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('启用每日提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text(
              _reminderService.enabled ? '每天 ${_formatTime(_reminderService.hour, _reminderService.minute)} 提醒' : '未启用',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            value: _reminderService.enabled,
            activeColor: Color(0xFF4A90E2),
            onChanged: (value) async {
              await _reminderService.setEnabled(value);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? '提醒已启用' : '提醒已关闭'),
                    backgroundColor: value ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
          ),
          if (_reminderService.enabled) ...[
            Divider(height: 1),
            ListTile(
              title: Text('提醒时间', style: TextStyle(fontSize: 16)),
              subtitle: Text(
                _formatTime(_reminderService.hour, _reminderService.minute),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
              ),
              trailing: Icon(Icons.access_time, color: Colors.grey[400]),
              onTap: _selectTime,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderService.hour, minute: _reminderService.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4A90E2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await _reminderService.setTime(picked.hour, picked.minute);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提醒时间已设置为 ${_formatTime(picked.hour, picked.minute)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
