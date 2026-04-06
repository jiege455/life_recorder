import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import 'add_record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _records = [];
  int _totalCount = 0;
  int _weekCount = 0;
  String? _mostUsedTag;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _dbHelper.getAllRecords();
    final totalCount = await _dbHelper.getRecordCount();
    final weekCount = await _dbHelper.getThisWeekCount();
    final mostUsedTag = await _dbHelper.getMostUsedTag();

    setState(() {
      _records = records;
      _totalCount = totalCount;
      _weekCount = weekCount;
      _mostUsedTag = mostUsedTag;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupRecordsByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    DateTime now = DateTime.now();

    for (var record in _records) {
      DateTime recordDate =
          DateTime.fromMillisecondsSinceEpoch(record['created_at']);
      String groupKey;

      if (_isSameDay(recordDate, now)) {
        groupKey = '今天';
      } else if (_isSameDay(recordDate, now.subtract(Duration(days: 1)))) {
        groupKey = '昨天';
      } else if (recordDate.isAfter(now.subtract(Duration(days: 7)))) {
        groupKey = '本周';
      } else {
        groupKey = '更早';
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(record);
    }

    return grouped;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData _getMoodIcon(String? mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'excited':
        return Icons.celebration;
      default:
        return Icons.sentiment_satisfied_alt;
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'happy':
        return Colors.amber;
      case 'neutral':
        return Colors.grey;
      case 'sad':
        return Colors.blue;
      case 'excited':
        return Colors.pink;
      default:
        return Colors.green;
    }
  }

  Color _getTagColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'AI人生记录器',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDeveloperInfo(),
          _buildStatsCards(),
          Expanded(child: _buildRecordsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecordPage()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: Color(0xFF4A90E2),
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderBottom: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '开发者：杰哥网络科技',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            'qq2711793818',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('总记录数', _totalCount.toString(), Icons.article,
              Color(0xFF4A90E2)),
          SizedBox(width: 12),
          _buildStatCard('本周记录', _weekCount.toString(), Icons.calendar_today,
              Color(0xFF50C878)),
          SizedBox(width: 12),
          _buildStatCard('最常用标签', _mostUsedTag ?? '暂无', Icons.tag,
              Color(0xFFFF6B6B)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 8),
          Text(value,
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    var grouped = _groupRecordsByDate();

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text('还没有记录',
                style: TextStyle(fontSize: 18, color: Colors.grey[500])),
            SizedBox(height: 8),
            Text('点击右下角 + 按钮开始记录生活',
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        String dateLabel = grouped.keys.elementAt(index);
        List<Map<String, dynamic>> records = grouped[dateLabel]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(dateLabel,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2))),
            ),
            ...records.map((record) => _buildRecordCard(record)),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(record['created_at']);
    String timeStr = DateFormat('HH:mm').format(dateTime);

    List<String> tags = [];
    if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
      try {
        tags = jsonDecode(record['tags'].toString());
      } catch (e) {}
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getMoodIcon(record['mood']),
                    color: _getMoodColor(record['mood']), size: 24),
                SizedBox(width: 8),
                Text(timeStr,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 12),
            Text(record['content'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, height: 1.5)),
            if (tags.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value,
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: _getTagColor(entry.key),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
