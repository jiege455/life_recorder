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
    try {
      final records = await _dbHelper.getAllRecords();
      final totalCount = await _dbHelper.getRecordCount();
      final weekCount = await _dbHelper.getThisWeekCount();
      final mostUsedTag = await _dbHelper.getMostUsedTag();

      if (mounted) {
        setState(() {
          _records = records;
          _totalCount = totalCount;
          _weekCount = weekCount;
          _mostUsedTag = mostUsedTag;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u52A0\u8F7D\u6570\u636E\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5')),
        );
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupRecordsByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    DateTime now = DateTime.now();

    for (var record in _records) {
      DateTime recordDate =
          DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
      String groupKey;

      if (_isSameDay(recordDate, now)) {
        groupKey = '\u4ECA\u5929';
      } else if (_isSameDay(recordDate, now.subtract(Duration(days: 1)))) {
        groupKey = '\u6628\u5929';
      } else if (recordDate.isAfter(now.subtract(Duration(days: 7)))) {
        groupKey = '\u672C\u5468';
      } else {
        groupKey = DateFormat('MM\u6708dd\u65E5').format(recordDate);
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

  void _deleteRecord(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\u786E\u8BA4\u5220\u9664'),
        content: Text('\u786E\u5B9A\u8981\u5220\u9664\u8FD9\u6761\u8BB0\u5F55\u5417\uFF1F'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('\u53D6\u6D88'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('\u5220\u9664', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteRecord(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
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

  Widget _buildStatsCards() {
    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('\u603B\u8BB0\u5F55\u6570', _totalCount.toString(), Icons.article,
              Color(0xFF4A90E2)),
          SizedBox(width: 12),
          _buildStatCard('\u672C\u5468\u8BB0\u5F55', _weekCount.toString(), Icons.calendar_today,
              Color(0xFF50C878)),
          SizedBox(width: 12),
          _buildStatCard('\u6700\u5E38\u7528\u6807\u7B7E', _mostUsedTag ?? '\u6682\u65E0', Icons.tag,
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
            Text('\u8FD8\u6CA1\u6709\u8BB0\u5F55',
                style: TextStyle(fontSize: 18, color: Colors.grey[500])),
            SizedBox(height: 8),
            Text('\u70B9\u51FB\u53F3\u4E0B\u89D2 + \u6309\u94AE\u5F00\u59CB\u8BB0\u5F55\u751F\u6D3B',
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\u5F00\u53D1\u8005\uFF1A\u6770\u54E5\u7F51\u7EDC\u79D1\u6280',
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

  Widget _buildRecordCard(Map<String, dynamic> record) {
    int timestamp = record['created_at'] ?? 0;
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String timeStr = DateFormat('HH:mm').format(dateTime);
    String content = record['content']?.toString() ?? '';
    int recordId = record['id'] ?? 0;

    List<String> tags = [];
    if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(record['tags'].toString());
        tags = decoded.map((e) => e.toString()).toList();
      } catch (e) {}
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _deleteRecord(recordId),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getMoodIcon(record['mood'] as String?),
                      color: _getMoodColor(record['mood'] as String?), size: 24),
                  SizedBox(width: 8),
                  Text(timeStr,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                    onPressed: () => _deleteRecord(recordId),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(content,
                  maxLines: 3,
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
      ),
    );
  }
}
