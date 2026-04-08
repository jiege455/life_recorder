import 'package:flutter/material.dart';
import '../services/lock_service.dart';

class LockSettingsPage extends StatefulWidget {
  const LockSettingsPage({super.key});

  @override
  State<LockSettingsPage> createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  final LockService _lockService = LockService.instance;
  bool _canUseBiometrics = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _lockService.canCheckBiometrics();
    final isSupported = await _lockService.isDeviceSupported();
    setState(() {
      _canUseBiometrics = canCheck && isSupported;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('隐私锁', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  _buildInfoCard(),
                  SizedBox(height: 24),
                  _buildLockToggle(),
                  if (_lockService.lockEnabled) ...[
                    SizedBox(height: 16),
                    _buildTestButton(),
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
                Text(
                  '保护你的隐私',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  '启用后，进入应用需要验证指纹或密码',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: SwitchListTile(
        title: Text('启用隐私锁', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(
          _canUseBiometrics ? '支持指纹和密码验证' : '仅支持密码验证',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        value: _lockService.lockEnabled,
        activeColor: Color(0xFF4A90E2),
        onChanged: (value) async {
          if (value) {
            if (!_canUseBiometrics) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('当前设备不支持生物识别'), backgroundColor: Colors.orange),
                );
              }
              return;
            }
            final success = await _lockService.authenticate();
            if (success) {
              await _lockService.setLockEnabled(true);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('隐私锁已启用'), backgroundColor: Colors.green),
                );
              }
            }
          } else {
            await _lockService.setLockEnabled(false);
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('隐私锁已关闭'), backgroundColor: Colors.orange),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final success = await _lockService.authenticate();
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('验证成功'), backgroundColor: Colors.green),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('验证失败'), backgroundColor: Colors.red),
            );
          }
        },
        icon: Icon(Icons.fingerprint),
        label: Text('测试验证'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
