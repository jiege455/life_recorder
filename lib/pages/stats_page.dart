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
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<double> _moodTrendData = [];
  List<FlSpot> _spots = [];

  final Map<String, String> _moodLabels = {'happy': '开心', 'neutral': '平静', 'sad': '难过', 'excited': '兴奋'};
  final Map<String, Color> _moodColors = {'happy': Colors.amber, 'neutral': Colors.grey, 'sad': Colors.blue, 'excited': Colors.pink};
  final Map<String, IconData> _moodIcons = {'happy': Icons.sentiment_very_satisfied, 'neutral': Icons.sentiment_neutral, 'sad': Icons.sentiment_dissatisfied, 'excited': Icons.celebration};

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    final moodStats = await _dbHelper.getMoodStats();
    final totalCount = await _dbHelper.getRecordCount();
    await _loadMoodTrend();
    if (mounted) { setState(() { _moodStats = moodStats; _totalCount = totalCount; _isLoading = false; }); }
  }

  Future<void> _loadMoodTrend() async {
    final data = await _dbHelper.getMonthlyMoodCounts(_selectedYear, _selectedMonth);
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) { if (data[i] > 0) spots.add(FlSpot(i.toDouble() + 1, data[i])); }
    setState(() { _moodTrendData = data; _spots = spots; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('心情统计', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary, elevation: 0, centerTitle: true, automaticallyImplyLeading: false,
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [_buildSummaryCard(), SizedBox(height: 16), _buildMoodTrendChart(), SizedBox(height: 16), _buildPieChart(), SizedBox(height: 16), _buildMoodBreakdown()]),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildSummaryItem(Icons.article, _totalCount.toString(), '总记录', Color(0xFF4A90E2)),
        _buildSummaryItem(Icons.mood, _moodStats.length.toString(), '心情种类', Colors.amber),
        _buildSummaryItem(Icons.star, _getDominantMood(), '主导心情', Colors.pink),
      ]),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Column(children: [Icon(icon, color: color, size: 28), SizedBox(height: 6), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))]);
  }

  String _getDominantMood() {
    if (_moodStats.isEmpty) return '-';
    var sorted = _moodStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _moodLabels[sorted.first.key] ?? sorted.first.key;
  }

  Widget _buildMoodTrendChart() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.cardColor;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(children: [
        Row(children: [Icon(Icons.show_chart, color: primaryColor, size: 20), SizedBox(width: 8), Text('心情趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), Spacer(), _buildMonthSelector()]),
        SizedBox(height: 20),
        SizedBox(height: 180, child: _spots.isEmpty ? Center(child: Text('本月暂无数据', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))) : LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: theme.colorScheme.outline.withOpacity(0.2), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 1, getTitlesWidget: (value, meta) { String label = ''; if (value == 1) label = '难过'; if (value == 2) label = '平静'; if (value == 3) label = '兴奋'; if (value == 4) label = '开心'; return Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)); })),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5, getTitlesWidget: (value, meta) => Text('${value.toInt()}日', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)))),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false), minX: 1, maxX: _moodTrendData.length.toDouble(), minY: 0, maxY: 4.5,
          lineBarsData: [LineChartBarData(spots: _spots, isCurved: true, color: primaryColor, barWidth: 3, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: primaryColor, strokeWidth: 2, strokeColor: cardColor)), belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.1)))],
        ))),
      ]),
    );
  }

  Widget _buildMonthSelector() {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    return Row(children: [
      IconButton(icon: Icon(Icons.chevron_left, color: subtitleColor), onPressed: () { setState(() { if (_selectedMonth == 1) { _selectedMonth = 12; _selectedYear--; } else { _selectedMonth--; } }); _loadMoodTrend(); }),
      Text('$_selectedYear 年$_selectedMonth 月', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
      IconButton(icon: Icon(Icons.chevron_right, color: subtitleColor), onPressed: () { final now = DateTime.now(); if (_selectedYear < now.year || (_selectedYear == now.year && _selectedMonth < now.month)) { setState(() { if (_selectedMonth == 12) { _selectedMonth = 1; _selectedYear++; } else { _selectedMonth++; } }); _loadMoodTrend(); } }),
    ]);
  }

  Widget _buildPieChart() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    if (_moodStats.isEmpty) return Container(height: 200, decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)), child: Center(child: Text('暂无数据', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))));
    List<PieChartSectionData> sections = [];
    _moodStats.forEach((mood, count) { sections.add(PieChartSectionData(color: _moodColors[mood] ?? Colors.green, value: count.toDouble(), title: '${_moodLabels[mood] ?? mood}\n$count', radius: 60, titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))); });
    return Container(
      padding: EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(children: [Row(children: [Icon(Icons.pie_chart, color: primaryColor, size: 20), SizedBox(width: 8), Text('心情分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]), SizedBox(height: 20), SizedBox(height: 200, child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40)))]),
    );
  }

  Widget _buildMoodBreakdown() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Container(
      padding: EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.bar_chart, color: primaryColor, size: 20), SizedBox(width: 8), Text('心情明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
        SizedBox(height: 16),
        ..._moodStats.entries.map((entry) {
          double percent = _totalCount > 0 ? (entry.value / _totalCount * 100) : 0;
          return Padding(padding: EdgeInsets.only(bottom: 12), child: Column(children: [
            Row(children: [Icon(_moodIcons[entry.key] ?? Icons.sentiment_satisfied_alt, color: _moodColors[entry.key] ?? Colors.green, size: 22), SizedBox(width: 8), Text(_moodLabels[entry.key] ?? entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), Spacer(), Text('${entry.value}条', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)), SizedBox(width: 8), Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)))]),
            SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percent / 100, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: _moodColors[entry.key] ?? Colors.green, minHeight: 8)),
          ]));
        }),
      ]),
    );
  }
}
