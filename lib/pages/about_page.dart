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
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '\u5173\u4E8E',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.auto_stories, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
                  ),
                  SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _getVersion(),
                    builder: (context, snapshot) {
                      return Text(
                        'v${snapshot.data ?? '2.0.0'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      );
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\u5F00\u53D1\u8005\uFF1A\u6770\u54E5\u7F51\u7EDC\u79D1\u6280',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF4A90E2), size: 20),
                      SizedBox(width: 8),
                      Text('\u529F\u80FD\u7279\u6027', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildFeatureItem(Icons.edit_note, '\u8BB0\u5F55\u751F\u6D3B\u70B9\u6EF4'),
                  _buildFeatureItem(Icons.mood, '\u5FC3\u60C5\u9009\u62E9'),
                  _buildFeatureItem(Icons.mic, '\u8BAF\u98DE\u8BED\u97F3\u8F93\u5165'),
                  _buildFeatureItem(Icons.auto_awesome, 'AI\u667A\u80FD\u6807\u7B7E'),
                  _buildFeatureItem(Icons.search, '\u641C\u7D22\u8BB0\u5F55'),
                  _buildFeatureItem(Icons.calendar_month, '\u65E5\u5386\u89C6\u56FE'),
                  _buildFeatureItem(Icons.bar_chart, '\u5FC3\u60C5\u7EDF\u8BA1\u56FE\u8868'),
                  _buildFeatureItem(Icons.auto_awesome, 'AI\u5468\u62A5/\u6708\u62A5'),
                  _buildFeatureItem(Icons.brightness_6, '\u6DF1\u8272\u6A21\u5F0F'),
                  _buildFeatureItem(Icons.label, '\u81EA\u5B9A\u4E49\u6807\u7B7E'),
                  _buildFeatureItem(Icons.image, '\u56FE\u7247\u8BB0\u5F55'),
                  _buildFeatureItem(Icons.backup, '\u6570\u636E\u5907\u4EFD\u4E0E\u6062\u590D'),
                  _buildFeatureItem(Icons.notifications, '\u6BCF\u65E5\u63D0\u9192'),
                  _buildFeatureItem(Icons.share, '\u5206\u4EAB\u529F\u80FD'),
                  _buildFeatureItem(Icons.lock, '\u9690\u79C1\u9501'),
                  _buildFeatureItem(Icons.calendar_today, '\u5E74\u5EA6\u56DE\u987E'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.memory, color: Color(0xFF4A90E2), size: 20),
                      SizedBox(width: 8),
                      Text('\u6280\u672F\u652F\u6301', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTechItem('Flutter', '\u8DE8\u5E73\u53F0\u6846\u67B6'),
                  _buildTechItem('DeepSeek', 'AI\u6807\u7B7E\u4E0E\u62A5\u544A\u751F\u6210'),
                  _buildTechItem('\u8BAF\u98DE', '\u8BED\u97F3\u8BC6\u522B'),
                  _buildTechItem('SQLite', '\u672C\u5730\u6570\u636E\u5B58\u50A8'),
                  _buildTechItem('fl_chart', '\u56FE\u8868\u53EF\u89C6\u5316'),
                  _buildTechItem('table_calendar', '\u65E5\u5386\u7EC4\u4EF6'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: Color(0xFF4A90E2), size: 20),
                      SizedBox(width: 8),
                      Text('\u6CD5\u5F8B\u4FE1\u606F', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildLinkItem(context, Icons.privacy_tip, '\u9690\u79C1\u653F\u7B56', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
                  }),
                  _buildLinkItem(context, Icons.description, '\u7528\u6237\u534F\u8BAE', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UserAgreementPage()));
                  }),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_support, color: Color(0xFF4A90E2), size: 20),
                      SizedBox(width: 8),
                      Text('\u8054\u7CFB\u6211\u4EEC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildContactItem(Icons.business, '\u6770\u54E5\u7F51\u7EDC\u79D1\u6280'),
                  _buildContactItem(Icons.chat, 'QQ\uFF1A2711793818'),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              '\u00A9 2026 \u6770\u54E5\u7F51\u7EDC\u79D1\u6280 \u7248\u6743\u6240\u6709',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF4A90E2)),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildTechItem(String name, String desc) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(name, style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2), fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 10),
          Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Color(0xFF4A90E2)),
            SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 14, color: Color(0xFF4A90E2))),
            Spacer(),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF4A90E2)),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
