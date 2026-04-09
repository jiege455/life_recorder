﻿import 'package:flutter/material.dart';
import '../services/lock_service.dart';

class LockSettingsPage extends StatefulWidget {
  const LockSettingsPage({super.key});

  @override
  State<LockSettingsPage> createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  final LockService _lockService = LockService.instance;
  bool _lockEnabled = false;
  bool _canUseBiometrics = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    _lockEnabled = _lockService.lockEnabled;
    final canCheck = await _lockService.canCheckBiometrics();
    final isSupported = await _lockService.isDeviceSupported();
    if (mounted) {
      setState(() {
        _canUseBiometrics = canCheck && isSupported;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('隐私锁', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
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
                  _buildInfoCard(),
                  SizedBox(height: 24),
                  _buildLockToggle(isDark, primaryColor),
                  if (_lockEnabled) ...[
                    SizedBox(height: 16),
                    _buildTestButton(primaryColor),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.security, size: 48, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('保护你的隐私', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('启用后，进入应用需要验证指纹或密码', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockToggle(bool isDark, Color primaryColor) {
    final cardColor = isDark ? Color(0xFF2A2A3E) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: SwitchListTile(
        title: Text('启用隐私锁', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(
          _canUseBiometrics ? '支持指纹/面容和密码验证' : '支持设备密码验证',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        value: _lockEnabled,
        activeColor: primaryColor,
        onChanged: _onToggleLock,
      ),
    );
  }

  void _onToggleLock(bool value) {
    setState(() {
      _lockEnabled = value;
    });

    _lockService.setLockEnabled(value).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '隐私锁已启用' : '隐私锁已关闭'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }).catchError((e) {
      if (!mounted) return;
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _lockEnabled = !value;
          });
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败，请重试'), backgroundColor: Colors.red),
      );
    });
  }

  Widget _buildTestButton(Color primaryColor) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final success = await _lockService.authenticate();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '验证成功' : '验证失败'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        },
        icon: Icon(Icons.fingerprint),
        label: Text('测试验证'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
