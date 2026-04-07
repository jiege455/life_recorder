import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, int> _moodStats = {};
  int _totalCount = 0;
  bool _isLoading = true;

  final Map<String, String> _moodLabels = {
    'happy': '\u5F00\u5FC3',
    'neutral': '\u5E73\u9759',
    'sad': '\u96BE\u8FC7',
    'excited': '\u5174\u594B',
  };

  final Map<String, Color> _moodColors = {
    'happy': Colors.amber,
    'neutral': Colors.grey,
    'sad': Colors.blue,
    'excited': Colors.pink,
  };

  final Map<String, IconData> _moodIcons = {
    'happy': Icons.sentiment_very_satisfied,
    'neutral': Icons.sentiment_neutral,
    'sad': Icons.sentiment_dissatisfied,
    'excited': Icons.celebration,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final moodStats = await _dbHelper.getMoodStats();
    final totalCount = await _dbHelper.getRecordCount();
    if (mounted) {
      setState(() {
        _moodStats = moodStats;
        _totalCount = totalCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('\u5FC3\u60C5\u7EDF\u8BA1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryCard(),
                  SizedBox(height: 16),
                  _buildPieChart(),
                  SizedBox(height: 16),
                  _buildMoodBreakdown(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(Icons.article, _totalCount.toString(), '\u603B\u8BB0\u5F55', Color(0xFF4A90E2)),
          _buildSummaryItem(Icons.mood, _moodStats.length.toString(), '\u5FC3\u60C5\u79CD\u7C7B', Colors.amber),
          _buildSummaryItem(Icons.star, _getDominantMood(), '\u4E3B\u5BFC\u5FC3\u60C5', Colors.pink),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  String _getDominantMood() {
    if (_moodStats.isEmpty) return '-';
    var sorted = _moodStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _moodLabels[sorted.first.key] ?? sorted.first.key;
  }

  Widget _buildPieChart() {
    if (_moodStats.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('\u6682\u65E0\u6570\u636E', style: TextStyle(color: Colors.grey[400]))),
      );
    }

    List<PieChartSectionData> sections = [];
    _moodStats.forEach((mood, count) {
      final color = _moodColors[mood] ?? Colors.green;
      sections.add(PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '${_moodLabels[mood] ?? mood}\n$count',
        radius: 60,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    });

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('\u5FC3\u60C5\u5206\u5E03', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBreakdown() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('\u5FC3\u60C5\u660E\u7EC6', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16),
          ..._moodStats.entries.map((entry) {
            double percent = _totalCount > 0 ? (entry.value / _totalCount * 100) : 0;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(_moodIcons[entry.key] ?? Icons.sentiment_satisfied_alt,
                          color: _moodColors[entry.key] ?? Colors.green, size: 22),
                      SizedBox(width: 8),
                      Text(_moodLabels[entry.key] ?? entry.key,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Spacer(),
                      Text('${entry.value}\u6761',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      SizedBox(width: 8),
                      Text('${percent.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                  SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.grey[200],
                      color: _moodColors[entry.key] ?? Colors.green,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
