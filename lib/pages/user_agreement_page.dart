import 'package:flutter/material.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('用户协议', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            _buildSection(context, '一、协议的接受与修改', '1.1 欢迎使用 AI 人生记录器（以下简称"本应用"）。\n\n1.2 当您下载、安装、使用本应用时，即表示您已阅读并同意本用户协议的所有内容。\n\n1.3 如果您不同意本协议的任何条款，请立即停止使用本应用。\n\n1.4 我们保留随时修改本协议的权利。修改后的协议一经公布即生效。'),
            _buildSection(context, '二、服务内容', '2.1 本应用提供以下服务：\n- 日记记录功能\n- 心情标签管理\n- 图片上传和展示\n- 日历视图\n- 数据统计和图表\n- AI 智能标签生成\n- AI 周报/月报生成\n- 语音输入功能\n- 数据备份和恢复\n- 每日提醒功能\n- 分享功能\n- 隐私锁功能\n- 年度回顾'),
            _buildSection(context, '三、用户行为规范', '3.1 您在使用本应用时，不得：\n- 发布违反法律法规的内容\n- 发布侵犯他人权益的内容\n- 发布虚假、误导性信息\n- 利用本应用从事违法犯罪活动\n- 对本应用进行反向工程、反编译\n- 使用任何方式干扰本应用的正常运行'),
            _buildSection(context, '四、知识产权', '4.1 本应用的所有内容（包括但不限于代码、界面设计、图标、文字）均受知识产权法保护。\n\n4.2 您在本应用中创建的内容（日记、图片等）归您所有。\n\n4.3 未经我们书面许可，您不得将本应用的任何内容用于商业目的。'),
            _buildSection(context, '五、隐私保护', '5.1 我们重视您的隐私保护。\n\n5.2 关于个人信息的收集、使用和保护，请详见《隐私政策》。\n\n5.3 您使用本应用即表示您同意我们按照隐私政策处理您的信息。'),
            _buildSection(context, '六、免责声明', '6.1 本应用按"现状"提供，不保证完全无错误或中断。\n\n6.2 对于因不可抗力（如网络故障、设备问题等）导致的数据丢失，我们不承担责任。\n\n6.3 建议您定期备份重要数据。\n\n6.4 第三方服务（如 AI 服务、语音识别）由其提供方负责，我们不承担相关责任。'),
            _buildSection(context, '七、服务的变更与终止', '7.1 我们保留随时变更、中断或终止服务的权利。\n\n7.2 如因法律法规变化或运营策略调整需要终止服务，我们将提前通知用户。\n\n7.3 服务终止后，您仍可导出本地数据。'),
            _buildSection(context, '八、争议解决', '8.1 本协议的解释、效力及纠纷的解决，适用中华人民共和国法律。\n\n8.2 若发生争议，双方应友好协商解决。\n\n8.3 协商不成的，任何一方可向开发者所在地人民法院提起诉讼。'),
            _buildSection(context, '九、其他条款', '9.1 本协议构成双方就本应用服务达成的完整协议。\n\n9.2 如本协议任何条款被认定为无效，不影响其他条款的效力。\n\n9.3 我们未行使或执行本协议任何权利或规定，不构成对该权利或规定的放弃。'),
            _buildSection(context, '十、联系我们', '如您对本协议有任何疑问或建议，请联系：\n\n开发者：杰哥网络科技\n联系方式：QQ 2711793818'),
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
