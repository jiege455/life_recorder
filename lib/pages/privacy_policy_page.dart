import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('隐私政策', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, '一、引言', '欢迎使用 AI 人生记录器（以下简称"本应用"）。我们非常重视您的隐私保护。本隐私政策说明我们如何收集、使用、存储和保护您的个人信息。请您在使用本应用前，仔细阅读并了解本隐私政策。'),
            _buildSection(context, '二、信息收集', '1. 您主动提供的信息：\n- 您记录的日记内容\n- 您选择的心情标签\n- 您上传的图片\n- 您设置的提醒时间\n- 您自定义的标签\n\n2. 自动收集的信息：\n- 设备信息\n- 使用习惯数据'),
            _buildSection(context, '三、信息使用', '我们使用收集的信息用于：\n- 提供日记记录功能\n- 生成统计报告和 AI 分析\n- 提供日历视图\n- 发送提醒通知\n- 改进用户体验'),
            _buildSection(context, '四、信息存储', '1. 本地存储：所有数据主要存储在您设备的本地数据库中\n2. 备份存储：当您使用备份功能时，数据会加密存储\n3. 我们不会将您的数据上传到我们的服务器'),
            _buildSection(context, '五、信息保护', '我们采取以下措施保护您的信息安全：\n- 数据加密存储\n- 支持密码/生物识别锁\n- 不向第三方共享数据\n- 定期安全更新'),
            _buildSection(context, '六、权限说明', '本应用可能需要以下权限：\n- 存储权限：用于保存图片\n- 相机权限：用于拍照\n- 通知权限：用于发送提醒\n- 网络权限：用于 AI 功能'),
            _buildSection(context, '七、第三方服务', '本应用集成了以下第三方服务：\n- DeepSeek AI：用于生成智能标签和报告\n- 讯飞语音：用于语音输入\n- 这些服务有其独立的隐私政策'),
            _buildSection(context, '八、隐私政策更新', '我们可能会不时更新本隐私政策。更新后的政策将在应用内发布，建议您定期查看。'),
            _buildSection(context, '九、联系我们', '如您对本隐私政策有任何疑问或建议，请联系：\n\n开发者：杰哥网络科技\n联系方式：QQ 2711793818'),
            SizedBox(height: 20),
            Text('最后更新日期：2026 年 1 月', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, height: 1.6)),
        ],
      ),
    );
  }
}
