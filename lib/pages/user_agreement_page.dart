import 'package:flutter/material.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户协议', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI人生记录器用户协议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2))),
              SizedBox(height: 8),
              Text('更新日期：2026年4月9日', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500])),
              Text('生效日期：2026年4月9日', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500])),
              SizedBox(height: 20),
              _buildSection('一、服务说明', 'AI人生记录器（以下简称"本应用"）是由杰哥网络科技开发的生活记录应用，提供文字记录、语音输入、图片记录、AI智能标签、心情统计、数据备份等功能。本应用运行在您的设备本地，核心数据存储在设备端。'),
              _buildSection('二、用户注册与账号', '本应用无需注册账号即可使用。所有数据存储在您的设备本地，不依赖云端账号系统。请您妥善保管设备，并定期使用数据备份功能。'),
              _buildSection('三、用户行为规范', '1. 您应当合法合规地使用本应用，不得利用本应用从事任何违反法律法规的活动。\n2. 您对通过本应用记录的内容承担全部责任。\n3. 您应当妥善保管设备及数据，因设备丢失、损坏等导致的数据丢失，开发者不承担责任。'),
              _buildSection('四、知识产权', '1. 本应用的所有知识产权（包括但不限于软件代码、界面设计、图标、文字等）归杰哥网络科技所有。\n2. 未经书面授权，您不得复制、修改、传播本应用的任何部分。\n3. 您通过本应用创建的记录内容，其知识产权归您所有。'),
              _buildSection('五、免责声明', '1. 本应用提供的AI标签生成和报告功能基于DeepSeek AI服务，生成内容仅供参考，不构成任何专业建议。\n2. 因网络原因导致AI功能无法使用，开发者不承担责任。\n3. 因设备故障、系统更新等原因导致的数据丢失，开发者不承担责任，建议您定期备份数据。\n4. 本应用不保证持续无错误运行，开发者将尽力修复已知问题。'),
              _buildSection('六、服务变更与终止', '1. 开发者有权根据需要修改或中断部分服务功能。\n2. 重大变更将通过应用内通知的方式告知您。\n3. 您可以随时停止使用本应用并删除设备上的数据。'),
              _buildSection('七、隐私保护', '本应用重视您的隐私保护，具体内容请参阅《隐私政策》。使用本应用即表示您同意本协议及隐私政策。'),
              _buildSection('八、争议解决', '1. 本协议的订立、执行和解释均适用中华人民共和国法律。\n2. 因本协议产生的争议，双方应友好协商解决；协商不成的，任何一方均可向开发者所在地有管辖权的人民法院提起诉讼。'),
              _buildSection('九、其他', '1. 本协议构成您与开发者之间关于使用本应用的完整协议。\n2. 开发者未行使或延迟行使本协议项下的任何权利，不构成对该权利的放弃。\n3. 本协议中任何条款被认定为无效的，不影响其他条款的效力。'),
              _buildSection('十、联系方式', '如果您对本协议有任何疑问，请通过以下方式联系我们：\n\n开发者：杰哥网络科技\nQQ：2711793818'),
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
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[800])),
          SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600], height: 1.8)),
        ],
      ),
    );
  }
}
