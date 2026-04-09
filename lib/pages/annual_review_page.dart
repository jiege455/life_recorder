import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import 'package:intl/intl.dart';

class AnnualReviewPage extends StatefulWidget {
  const AnnualReviewPage({super.key});

  @override
  State<AnnualReviewPage> createState() => _AnnualReviewPageState();
}

class _AnnualReviewPageState extends State<AnnualReviewPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  int _selectedYear = DateTime.now().year;
  Map<String, int> _moodStats = {};
  int _totalRecords = 0;
  String? _reviewContent;
  bool _isLoading = false;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _yearRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await _dbHelper.getYearRecords(_selectedYear);
    final moodStats = await _dbHelper.getYearlyMoodStats(_selectedYear);
    final totalCount = await _dbHelper.getRecordCount();
    if (mounted) {
      setState(() {
        _yearRecords = records;
        _moodStats = moodStats;
        _totalRecords = totalCount;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateReview() async {
    if (_yearRecords.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('该年度暂无记录'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final content = await _aiService.generateAnnualReview(
        _yearRecords,
        _selectedYear.toString(),
        _moodStats,
      );
      if (mounted) {
        setState(() {
          _reviewContent = content;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('年度回顾', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildYearSelector(),
                  SizedBox(height: 16),
                  _buildSummaryCard(),
                  SizedBox(height: 16),
                  _buildMoodOverview(),
                  SizedBox(height: 16),
                  _buildGenerateButton(),
                  if (_reviewContent != null) ...[
                    SizedBox(height: 16),
                    _buildReviewContent(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600]),
            onPressed: () {
              setState(() => _selectedYear--);
              _loadData();
            },
          ),
          Text(
            '$_selectedYear',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
          ),
          Text(
            ' 年',
            style: TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600]),
          ),
          if (_selectedYear < DateTime.now().year)
            IconButton(
              icon: Icon(Icons.chevron_right, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600]),
              onPressed: () {
                setState(() => _selectedYear++);
                _loadData();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final yearRecords = _yearRecords.length;
    final moodCount = _moodStats.values.fold<int>(0, (sum, count) => sum + count);
    final dominantMood = _getDominantMood();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$_selectedYear',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(yearRecords.toString(), '年度记录', Icons.article),
              _buildSummaryItem(moodCount.toString(), '心情时刻', Icons.mood),
              _buildSummaryItem(dominantMood, '主导心情', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  String _getDominantMood() {
    if (_moodStats.isEmpty) return '-';
    var sorted = _moodStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _getMoodLabel(sorted.first.key);
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'happy':
        return '开心';
      case 'neutral':
        return '平静';
      case 'sad':
        return '难过';
      case 'excited':
        return '兴奋';
      default:
        return '平静';
    }
  }

  Widget _buildMoodOverview() {
    if (_moodStats.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('暂无心情数据', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400])),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('心情分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16),
          ..._moodStats.entries.map((entry) {
            final total = _moodStats.values.fold<int>(0, (sum, v) => sum + v);
            final percent = total > 0 ? (entry.value / total * 100) : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(_getMoodLabel(entry.key), style: TextStyle(fontSize: 14)),
                      Spacer(),
                      Text('${entry.value}次', style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600])),
                      SizedBox(width: 8),
                      Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400])),
                    ],
                  ),
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                      color: _getMoodColor(entry.key),
                      minHeight: 6,
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

  Color _getMoodColor(String mood) {
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

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateReview,
        icon: _isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Icon(Icons.auto_awesome),
        label: Text(_isGenerating ? '正在生成...' : '生成年度回顾报告',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    return Container(
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
          Row(
            children: [
              Icon(Icons.description, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('$_selectedYear年度回顾', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16),
          SelectableText(
            _reviewContent!,
            style: TextStyle(fontSize: 15, height: 1.8, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
