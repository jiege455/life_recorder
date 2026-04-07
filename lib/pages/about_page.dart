import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                  Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                  _buildFeatureItem(Icons.bar_chart, '\u7EDF\u8BA1\u5206\u6790'),
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
                  _buildTechItem('DeepSeek', 'AI\u6807\u7B7E\u751F\u6210'),
                  _buildTechItem('\u8BAF\u98DE', '\u8BED\u97F3\u8BC6\u522B'),
                  _buildTechItem('SQLite', '\u672C\u5730\u6570\u636E\u5B58\u50A8'),
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
