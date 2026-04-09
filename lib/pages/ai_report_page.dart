import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/ai_service.dart';

class AiReportPage extends StatefulWidget {
  const AiReportPage({super.key});

  @override
  State<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends State<AiReportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  String _reportType = 'week';
  String? _reportContent;
  bool _isGenerating = false;
  int _recordCount = 0;

  @override
  void initState() {
    super.initState();
    _checkRecordCount();
  }

  Future<void> _checkRecordCount() async {
    final count = await _dbHelper.getRecordCount();
    setState(() {
      _recordCount = count;
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      DateTime now = DateTime.now();
      DateTime start;
      String period;

      if (_reportType == 'week') {
        start = now.subtract(Duration(days: 7));
        period = '本周';
      } else {
        start = DateTime(now.year, now.month, 1);
        period = '本月';
      }

      final records = await _dbHelper.getRecordsForPeriod(start, now);

      if (records.isEmpty) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _reportContent = '$period还没有记录，先记录一些生活再来生成报告吧~';
          });
        }
        return;
      }

      final report = await _aiService.generateReport(records, period);
      if (mounted) {
        setState(() {
          _reportContent = report;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('报告生成失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI生活报告', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTypeSelector(),
            SizedBox(height: 16),
            _buildGenerateButton(),
            SizedBox(height: 16),
            if (_isGenerating) _buildLoading(),
            if (_reportContent != null && !_isGenerating) _buildReportContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
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
              Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('选择报告类型', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reportType = 'week'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _reportType == 'week' ? Color(0xFF4A90E2) : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('周报',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _reportType == 'week' ? Colors.white : theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reportType = 'month'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _reportType == 'month' ? Color(0xFF4A90E2) : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('月报',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _reportType == 'month' ? Colors.white : theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateReport,
        icon: Icon(Icons.auto_awesome, size: 20),
        label: Text(_isGenerating ? '正在生成...' : '生成AI报告',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF4A90E2)),
          SizedBox(height: 16),
          Text('AI正在分析你的生活记录...', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
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
              Text('${_reportType == 'week' ? '周' : '月'}报内容',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16),
          SelectableText(
            _reportContent!,
            style: TextStyle(fontSize: 15, height: 1.8, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
