import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('隐私政策', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI人生记录器隐私政策', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2))),
              SizedBox(height: 8),
              Text('更新日期：2026年4月9日', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text('生效日期：2026年4月9日', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              SizedBox(height: 20),
              _buildSection('一、我们收集的信息', 'AI人生记录器尊重并保护您的个人隐私。我们收集的信息如下：\n\n1. 您主动输入的内容：包括文字记录、心情选择、自定义标签等。\n2. 您主动上传的图片：您选择拍照或从相册选取的图片。\n3. 语音数据：当您使用语音输入功能时，语音数据将发送至讯飞语音识别服务进行文字转换，我们不会存储您的语音录音。\n4. 设备信息：应用仅在本地运行，不主动收集设备标识符等信息。'),
              _buildSection('二、信息存储方式', '1. 所有记录数据（文字、心情、标签、图片路径）均存储在您的设备本地SQLite数据库中。\n2. 图片文件存储在您的设备应用文档目录中。\n3. 我们不设有中央服务器存储您的个人数据。\n4. 您可以随时通过应用的"导出数据"功能备份，或通过"清除所有数据"功能删除全部数据。'),
              _buildSection('三、信息使用目的', '1. 为您提供生活记录、心情追踪等核心功能。\n2. 使用DeepSeek AI服务为您自动生成标签和报告。\n3. 使用讯飞语音识别服务将您的语音转换为文字。'),
              _buildSection('四、第三方服务', '本应用使用以下第三方服务：\n\n1. DeepSeek AI（深度求索）\n   - 用途：AI标签生成、AI周报/月报生成、年度回顾\n   - 数据传输：您输入的文字内容会通过加密连接发送至DeepSeek服务器\n   - 隐私政策：https://www.deepseek.com/privacy\n\n2. 讯飞语音识别（科大讯飞）\n   - 用途：语音转文字功能\n   - 数据传输：语音数据通过加密连接发送至讯飞服务器\n   - 隐私政策：https://www.xfyun.cn/doc/policy/yinsi.html\n\n我们不会将您的数据出售或分享给其他第三方。'),
              _buildSection('五、权限说明', '本应用申请以下权限：\n\n1. 麦克风权限：用于语音输入记录\n2. 相机权限：用于拍照记录\n3. 相册权限：用于选择图片记录\n4. 生物识别权限：用于隐私锁功能\n5. 通知权限：用于每日提醒功能\n6. 存储权限：用于数据备份与恢复\n\n所有权限仅在您主动使用相关功能时请求，您可以随时在系统设置中关闭。'),
              _buildSection('六、数据安全', '1. 所有本地数据存储在应用沙盒中，其他应用无法访问。\n2. 网络传输均使用HTTPS加密。\n3. 提供隐私锁功能（指纹/Face ID）保护您的数据。\n4. 建议您定期使用数据导出功能进行备份。'),
              _buildSection('七、您的权利', '1. 查看权：您可以随时查看所有记录数据。\n2. 导出权：您可以通过"导出数据"功能导出全部数据。\n3. 删除权：您可以删除单条记录，或通过"清除所有数据"功能删除全部数据。\n4. 撤回同意权：您可以随时在系统设置中关闭已授予的权限。'),
              _buildSection('八、未成年人保护', '我们高度重视对未成年人个人信息的保护。若您是未满14周岁的未成年人，请在监护人的陪同和指导下使用本应用。'),
              _buildSection('九、隐私政策更新', '我们可能会适时修订本隐私政策。政策更新后，我们会在应用内通知您。若您在政策更新后继续使用本应用，即视为您同意受修订后的隐私政策约束。'),
              _buildSection('十、联系我们', '如果您对本隐私政策有任何疑问、意见或建议，请通过以下方式联系我们：\n\n开发者：杰哥网络科技\nQQ：2711793818'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.8)),
        ],
      ),
    );
  }
}
