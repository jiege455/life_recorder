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
        title: Text('\u9690\u79C1\u9501', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  '\u4FDD\u62A4\u4F60\u7684\u9690\u79C1',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  '\u542F\u7528\u540E\uFF0C\u8FDB\u5165\u5E94\u7528\u9700\u8981\u9A8C\u8BC1\u6307\u7EB9\u6216\u5BC6\u7801',
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
        title: Text('\u542F\u7528\u9690\u79C1\u9501', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(
          _canUseBiometrics ? '\u652F\u6301\u6307\u7EB9\u548C\u5BC6\u7801\u9A8C\u8BC1' : '\u4EC5\u652F\u6301\u5BC6\u7801\u9A8C\u8BC1',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        value: _lockService.lockEnabled,
        activeColor: Color(0xFF4A90E2),
        onChanged: (value) async {
          if (value) {
            if (!_canUseBiometrics) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('\u5F53\u524D\u8BBE\u5907\u4E0D\u652F\u6301\u751F\u7269\u8BC6\u522B'), backgroundColor: Colors.orange),
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
                  SnackBar(content: Text('\u9690\u79C1\u9501\u5DF2\u542F\u7528'), backgroundColor: Colors.green),
                );
              }
            }
          } else {
            final success = await _lockService.authenticate();
            if (success) {
              await _lockService.setLockEnabled(false);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('\u9690\u79C1\u9501\u5DF2\u5173\u95ED'), backgroundColor: Colors.orange),
                );
              }
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
              SnackBar(content: Text('\u9A8C\u8BC1\u6210\u529F'), backgroundColor: Colors.green),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('\u9A8C\u8BC1\u5931\u8D25'), backgroundColor: Colors.red),
            );
          }
        },
        icon: Icon(Icons.fingerprint),
        label: Text('\u6D4B\u8BD5\u9A8C\u8BC1'),
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