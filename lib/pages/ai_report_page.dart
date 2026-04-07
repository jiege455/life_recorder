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
        period = '\u672C\u5468';
      } else {
        start = DateTime(now.year, now.month, 1);
        period = '\u672C\u6708';
      }

      final records = await _dbHelper.getRecordsForPeriod(start, now);

      if (records.isEmpty) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _reportContent = '$period\u8FD8\u6CA1\u6709\u8BB0\u5F55\uFF0C\u5148\u8BB0\u5F55\u4E00\u4E9B\u751F\u6D3B\u518D\u6765\u751F\u6210\u62A5\u544A\u5427~';
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
          SnackBar(content: Text('\u62A5\u544A\u751F\u6210\u5931\u8D25\uFF1A$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('AI\u751F\u6D3B\u62A5\u544A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
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
    return Container(
      padding: EdgeInsets.all(16),
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
              Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('\u9009\u62E9\u62A5\u544A\u7C7B\u578B', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                      color: _reportType == 'week' ? Color(0xFF4A90E2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('\u5468\u62A5',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _reportType == 'week' ? Colors.white : Colors.grey[600])),
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
                      color: _reportType == 'month' ? Color(0xFF4A90E2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('\u6708\u62A5',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _reportType == 'month' ? Colors.white : Colors.grey[600])),
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
        label: Text(_isGenerating ? '\u6B63\u5728\u751F\u6210...' : '\u751F\u6210AI\u62A5\u544A',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A90E2),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF4A90E2)),
          SizedBox(height: 16),
          Text('AI\u6B63\u5728\u5206\u6790\u4F60\u7684\u751F\u6D3B\u8BB0\u5F55...', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Container(
      width: double.infinity,
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
              Icon(Icons.description, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('${_reportType == 'week' ? '\u5468' : '\u6708'}\u62A5\u5185\u5BB9',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16),
          SelectableText(
            _reportContent!,
            style: TextStyle(fontSize: 15, height: 1.8, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
