import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<String> _getVersion() async {
    try {
      final version = await MethodChannel('flutter/version').invokeMethod<String>('getVersion');
      return version ?? '2.0.0';
    } catch (e) {
      return '2.0.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('关于', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                            child: Icon(Icons.access_time, size: 40, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('AI人生记录器', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                  SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _getVersion(),
                    builder: (context, snapshot) {
                      return Text('v${snapshot.data ?? '2.0.0'}', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant));
                    },
                  ),
                  SizedBox(height: 4),
                  Text('开发者：杰哥网络科技', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildCard(context, cardColor, Icons.info_outline, '功能特性', [
              _buildFeatureItem(Icons.edit_note, '记录生活点滴', context),
              _buildFeatureItem(Icons.mood, '心情选择', context),
              _buildFeatureItem(Icons.mic, '讯飞语音输入', context),
              _buildFeatureItem(Icons.auto_awesome, 'AI 智能标签', context),
              _buildFeatureItem(Icons.search, '搜索记录', context),
              _buildFeatureItem(Icons.calendar_month, '日历视图', context),
              _buildFeatureItem(Icons.bar_chart, '心情统计图表', context),
              _buildFeatureItem(Icons.auto_awesome, 'AI 周报/月报', context),
              _buildFeatureItem(Icons.brightness_6, '深色模式', context),
              _buildFeatureItem(Icons.label, '自定义标签', context),
              _buildFeatureItem(Icons.image, '图片记录', context),
              _buildFeatureItem(Icons.backup, '数据备份与恢复', context),
              _buildFeatureItem(Icons.notifications, '每日提醒', context),
              _buildFeatureItem(Icons.share, '分享功能', context),
              _buildFeatureItem(Icons.lock, '隐私锁', context),
              _buildFeatureItem(Icons.calendar_today, '年度回顾', context),
            ]),
            SizedBox(height: 16),
            _buildCard(context, cardColor, Icons.memory, '技术支持', [
              _buildTechItem('Flutter', '跨平台框架', primaryColor, context),
              _buildTechItem('DeepSeek', 'AI 标签与报告生成', primaryColor, context),
              _buildTechItem('讯飞', '语音识别', primaryColor, context),
              _buildTechItem('SQLite', '本地数据存储', primaryColor, context),
              _buildTechItem('fl_chart', '图表可视化', primaryColor, context),
              _buildTechItem('table_calendar', '日历组件', primaryColor, context),
            ]),
            SizedBox(height: 16),
            _buildCard(context, cardColor, Icons.gavel, '法律信息', [
              _buildLinkItem(context, Icons.privacy_tip, '隐私政策', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
              }, primaryColor),
              _buildLinkItem(context, Icons.description, '用户协议', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserAgreementPage()));
              }, primaryColor),
            ]),
            SizedBox(height: 16),
            _buildCard(context, cardColor, Icons.contact_support, '联系我们', [
              _buildContactItem(Icons.business, '杰哥网络科技', context),
              _buildContactItem(Icons.chat, 'QQ:2711793818', context),
            ]),
            SizedBox(height: 24),
            Text('© 2026 杰哥网络科技 版权所有', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color cardColor, IconData icon, String title, List<Widget> children) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: primaryColor, size: 20), SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(children: [Icon(icon, size: 18, color: theme.colorScheme.primary), SizedBox(width: 10), Text(text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface))]),
    );
  }

  Widget _buildTechItem(String name, String desc, Color primaryColor, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(name, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 10),
          Text(desc, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, IconData icon, String text, VoidCallback onTap, Color primaryColor) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 14, color: primaryColor)),
            Spacer(),
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(children: [Icon(icon, size: 18, color: theme.colorScheme.primary), SizedBox(width: 10), Text(text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface))]),
    );
  }
}
