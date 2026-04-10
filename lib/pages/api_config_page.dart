import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/speech_service.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final TextEditingController _deepseekController = TextEditingController();
  final TextEditingController _iflyAppIdController = TextEditingController();
  final TextEditingController _iflyAppKeyController = TextEditingController();
  final TextEditingController _iflyAppSecretController = TextEditingController();

  bool _obscureDeepseek = true;
  bool _obscureIflyKey = true;
  bool _obscureIflySecret = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    _deepseekController.text = ApiConfig.deepseekApiKey;
    _iflyAppIdController.text = ApiConfig.iflyAppId;
    _iflyAppKeyController.text = ApiConfig.iflyAppKey;
    _iflyAppSecretController.text = ApiConfig.iflyAppSecret;
  }

  @override
  void dispose() {
    _deepseekController.dispose();
    _iflyAppIdController.dispose();
    _iflyAppKeyController.dispose();
    _iflyAppSecretController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await ApiConfig.setDeepseekApiKey(_deepseekController.text.trim());
      await ApiConfig.setIflyConfig(
        appId: _iflyAppIdController.text.trim(),
        appKey: _iflyAppKeyController.text.trim(),
        appSecret: _iflyAppSecretController.text.trim(),
      );
      SpeechService().reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API密钥配置已保存'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败，请重试'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('恢复默认密钥'),
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('将恢复为应用内置的默认API密钥。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiConfig.resetToDefaults();
      _loadConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已恢复默认密钥'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('API密钥配置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveConfig,
            icon: Icon(Icons.save, color: Colors.white, size: 20),
            label: Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 24),
            _buildSectionTitle('🤖 DeepSeek AI 密钥', '用于AI智能标签、周报/月报、年度回顾'),
            SizedBox(height: 12),
            _buildDeepseekSection(),
            SizedBox(height: 24),
            _buildSectionTitle('🎤 科大讯飞语音密钥', '用于语音识别转文字'),
            SizedBox(height: 12),
            _buildIflySection(),
            SizedBox(height: 32),
            _buildResetButton(),
            SizedBox(height: 40),
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
          colors: [Color(0xFF4A90E2), Color(0xFF6C5CE7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, size: 32, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API密钥配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('开发者：杰哥网络科技', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '如果语音识别或AI标签功能提示密钥错误，请在此配置您自己的API密钥。密钥将安全保存在本地设备中。',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildDeepseekSection() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _deepseekController,
            obscureText: _obscureDeepseek,
            decoration: InputDecoration(
              labelText: 'DeepSeek API Key',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_obscureDeepseek ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscureDeepseek = !_obscureDeepseek),
                  ),
                ],
              ),
              hintText: 'sk-xxxxxx',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF4A90E2)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '前往 platform.deepseek.com 注册并获取API密钥',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIflySection() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _iflyAppIdController,
            decoration: InputDecoration(
              labelText: 'AppID',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2)),
              hintText: '讯飞开放平台AppID',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _iflyAppKeyController,
            obscureText: _obscureIflyKey,
            decoration: InputDecoration(
              labelText: 'APISecret',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2)),
              suffixIcon: IconButton(
                icon: Icon(_obscureIflyKey ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscureIflyKey = !_obscureIflyKey),
              ),
              hintText: '讯飞开放平台APISecret',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _iflyAppSecretController,
            obscureText: _obscureIflySecret,
            decoration: InputDecoration(
              labelText: 'APIKey',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2)),
              suffixIcon: IconButton(
                icon: Icon(_obscureIflySecret ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscureIflySecret = !_obscureIflySecret),
              ),
              hintText: '讯飞开放平台APIKey',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF4A90E2)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '前往 xfyun.cn 注册并创建语音听写应用获取密钥',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _resetToDefaults,
        icon: Icon(Icons.restore, size: 18),
        label: Text('恢复默认密钥'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: BorderSide(color: Colors.orange),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
