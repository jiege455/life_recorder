import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../database/database_helper.dart';
import '../widgets/share_card.dart';
import 'add_record_page.dart';
import 'record_detail_page.dart';
import 'calendar_page.dart';
import 'stats_page.dart';
import 'ai_report_page.dart';
import 'about_page.dart';
import 'settings_page.dart';
import 'annual_review_page.dart';
import '../services/theme_service.dart';

class HomePage extends StatefulWidget {
  final ThemeService? themeService;

  const HomePage({super.key, this.themeService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  int _totalCount = 0;
  int _weekCount = 0;
  String? _mostUsedTag;
  bool _isSearching = false;
  String? _selectedMoodFilter;
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '\u5F00\u5FC3'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '\u5E73\u9759'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '\u96BE\u8FC7'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '\u5174\u594B'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          _filteredRecords = _applyFilters(records);
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

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> records) {
    var filtered = records;
    if (_selectedMoodFilter != null) {
      filtered = filtered.where((r) => r['mood'] == _selectedMoodFilter).toList();
    }
    return filtered;
  }

  void _searchRecords(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _filteredRecords = _applyFilters(_records);
      });
      return;
    }
    final results = await _dbHelper.searchRecords(keyword);
    if (mounted) {
      setState(() {
        _filteredRecords = _applyFilters(results);
      });
    }
  }

  void _filterByMood(String? mood) {
    setState(() {
      _selectedMoodFilter = mood;
      _filteredRecords = _applyFilters(_records);
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupRecordsByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    DateTime now = DateTime.now();

    for (var record in _filteredRecords) {
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
      case 'happy': return Icons.sentiment_very_satisfied;
      case 'neutral': return Icons.sentiment_neutral;
      case 'sad': return Icons.sentiment_dissatisfied;
      case 'excited': return Icons.celebration;
      default: return Icons.sentiment_satisfied_alt;
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'happy': return Colors.amber;
      case 'neutral': return Colors.grey;
      case 'sad': return Colors.blue;
      case 'excited': return Colors.pink;
      default: return Colors.green;
    }
  }

  Color _getTagColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red];
    return colors[index % colors.length];
  }

  void _deleteRecord(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\u786E\u8BA4\u5220\u9664'),
        content: Text('\u786E\u5B9A\u8981\u5220\u9664\u8FD9\u6761\u8BB0\u5F55\u5417\uFF1F'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('\u53D6\u6D88')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('\u5220\u9664', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteRecord(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\u5DF2\u5220\u9664')));
      }
    }
  }

  void _shareRecord(Map<String, dynamic> record) async {
    String content = record['content']?.toString() ?? '';
    String mood = _getMoodLabel(record['mood']);
    String moodEmoji = _getMoodEmoji(record['mood']);
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
    String dateStr = DateFormat('yyyy\u5E74MM\u6708dd\u65E5 HH:mm').format(dt);

    List<String> tags = [];
    if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(record['tags'].toString());
        tags = decoded.map((e) => e.toString()).toList();
      } catch (e) {}
    }

    List<String> images = [];
    if (record['images'] != null && record['images'].toString().isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(record['images'].toString());
        images = decoded.map((e) => e.toString()).toList();
      } catch (e) {}
    }

    await ShareCardHelper.shareAsImage(
      context,
      content: content,
      mood: mood,
      moodEmoji: moodEmoji,
      dateStr: dateStr,
      tags: tags,
      images: images.isNotEmpty ? images : null,
    );
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'happy': return '\u{1F60A}';
      case 'neutral': return '\u{1F610}';
      case 'sad': return '\u{1F622}';
      case 'excited': return '\u{1F389}';
      default: return '\u{1F610}';
    }
  }

  String _getMoodLabel(String? mood) {
    switch (mood) {
      case 'happy': return '\u5F00\u5FC3';
      case 'neutral': return '\u5E73\u9759';
      case 'sad': return '\u96BE\u8FC7';
      case 'excited': return '\u5174\u594B';
      default: return '\u5E73\u9759';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          CalendarPage(),
          StatsPage(),
          AiReportPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF4A90E2),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '\u9996\u9875'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '\u65E5\u5386'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '\u7EDF\u8BA1'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI\u62A5\u544A'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddRecordPage()),
                );
                if (result == true) _loadData();
              },
              backgroundColor: Color(0xFF4A90E2),
              child: Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: '\u641C\u7D22\u8BB0\u5F55...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _searchRecords,
              )
            : Text('AI\u4EBA\u751F\u8BB0\u5F55\u5668', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredRecords = _applyFilters(_records);
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'about') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
              } else if (value == 'settings') {
                final themeService = await ThemeService.getInstance();
                if (mounted) {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(themeService: themeService)));
                  _loadData();
                }
              } else if (value == 'annual') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AnnualReviewPage()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 20, color: Color(0xFF4A90E2)), SizedBox(width: 8), Text('\u8BBE\u7F6E')])),
              PopupMenuItem(value: 'annual', child: Row(children: [Icon(Icons.calendar_today, size: 20, color: Color(0xFF4A90E2)), SizedBox(width: 8), Text('\u5E74\u5EA6\u56DE\u987E')])),
              PopupMenuItem(value: 'about', child: Row(children: [Icon(Icons.info_outline, size: 20, color: Color(0xFF4A90E2)), SizedBox(width: 8), Text('\u5173\u4E8E')])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          _buildMoodFilter(),
          Expanded(child: _buildRecordsList()),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      height: 110,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('\u603B\u8BB0\u5F55\u6570', _totalCount.toString(), Icons.article, Color(0xFF4A90E2)),
          SizedBox(width: 12),
          _buildStatCard('\u672C\u5468\u8BB0\u5F55', _weekCount.toString(), Icons.calendar_today, Color(0xFF50C878)),
          SizedBox(width: 12),
          _buildStatCard('\u6700\u5E38\u7528\u6807\u7B7E', _mostUsedTag ?? '\u6682\u65E0', Icons.tag, Color(0xFFFF6B6B)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 22), SizedBox(width: 6), Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMoodFilter() {
    return Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('\u5168\u90E8'),
              selected: _selectedMoodFilter == null,
              onSelected: (_) => _filterByMood(null),
              selectedColor: Color(0xFF4A90E2).withOpacity(0.2),
              backgroundColor: Colors.white,
              side: BorderSide(color: _selectedMoodFilter == null ? Color(0xFF4A90E2) : Colors.grey[300]!),
              labelStyle: TextStyle(color: _selectedMoodFilter == null ? Color(0xFF4A90E2) : Colors.grey[600], fontSize: 13),
            ),
          ),
          ..._moods.map((mood) => Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${mood['emoji']} ${mood['label']}'),
              selected: _selectedMoodFilter == mood['value'],
              onSelected: (_) => _filterByMood(mood['value']),
              selectedColor: Color(0xFF4A90E2).withOpacity(0.2),
              backgroundColor: Colors.white,
              side: BorderSide(color: _selectedMoodFilter == mood['value'] ? Color(0xFF4A90E2) : Colors.grey[300]!),
              labelStyle: TextStyle(color: _selectedMoodFilter == mood['value'] ? Color(0xFF4A90E2) : Colors.grey[600], fontSize: 13),
            ),
          )),
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
            Text(_isSearching ? '\u6CA1\u6709\u627E\u5230\u76F8\u5173\u8BB0\u5F55' : '\u8FD8\u6CA1\u6709\u8BB0\u5F55', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
            SizedBox(height: 8),
            Text(_isSearching ? '\u8BD5\u8BD5\u5176\u4ED6\u5173\u952E\u8BCD' : '\u70B9\u51FB\u53F3\u4E0B\u89D2 + \u6309\u94AE\u5F00\u59CB\u8BB0\u5F55\u751F\u6D3B', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
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
              if (index > 0) SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Color(0xFF4A90E2).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(dateLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2))),
              ),
              ...records.map((record) => _buildRecordCard(record)),
            ],
          );
        },
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

    List<String> images = [];
    if (record['images'] != null && record['images'].toString().isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(record['images'].toString());
        images = decoded.map((e) => e.toString()).toList();
      } catch (e) {}
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => RecordDetailPage(recordId: recordId)));
          if (result == true) _loadData();
        },
        onLongPress: () => _deleteRecord(recordId),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getMoodIcon(record['mood'] as String?), color: _getMoodColor(record['mood'] as String?), size: 22),
                  SizedBox(width: 8),
                  Text(timeStr, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.grey[400], size: 18),
                    onPressed: () => _shareRecord(record),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 18),
                    onPressed: () => _deleteRecord(recordId),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, height: 1.5)),
              if (images.isNotEmpty) ...[
                SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        height: 80,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(images[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image, color: Colors.grey[400]);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value, style: TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: _getTagColor(entry.key),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(horizontal: 8),
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
