import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '关于',
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
                    'AI人生记录器',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'v1.2.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '开发者：杰哥网络科技',
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
                      Text('功能特性', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildFeatureItem(Icons.edit_note, '记录生活点滴'),
                  _buildFeatureItem(Icons.mood, '心情选择'),
                  _buildFeatureItem(Icons.mic, '讯飞语音输入'),
                  _buildFeatureItem(Icons.auto_awesome, 'AI智能标签'),
                  _buildFeatureItem(Icons.search, '搜索记录'),
                  _buildFeatureItem(Icons.calendar_month, '日历视图'),
                  _buildFeatureItem(Icons.bar_chart, '心情统计图表'),
                  _buildFeatureItem(Icons.auto_awesome, 'AI周报/月报'),
                  _buildFeatureItem(Icons.brightness_6, '深色模式'),
                  _buildFeatureItem(Icons.label, '自定义标签'),
                  _buildFeatureItem(Icons.image, '图片记录'),
                  _buildFeatureItem(Icons.backup, '数据备份与恢复'),
                  _buildFeatureItem(Icons.notifications, '每日提醒'),
                  _buildFeatureItem(Icons.share, '分享功能'),
                  _buildFeatureItem(Icons.lock, '隐私锁'),
                  _buildFeatureItem(Icons.calendar_today, '年度回顾'),
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
                      Text('技术支持', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTechItem('Flutter', '跨平台框架'),
                  _buildTechItem('DeepSeek', 'AI标签与报告生成'),
                  _buildTechItem('讯飞', '语音识别'),
                  _buildTechItem('SQLite', '本地数据存储'),
                  _buildTechItem('fl_chart', '图表可视化'),
                  _buildTechItem('table_calendar', '日历组件'),
                ],
              ),
            ),
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
}
