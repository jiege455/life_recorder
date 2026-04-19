import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../services/app_events.dart';
import 'record_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedDayRecords = [];
  List<Map<String, dynamic>> _allRecords = [];
  String _viewMode = 'calendar';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
    AppEvents().recordChanged.listen((_) {
      if (mounted) _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final records = await _dbHelper.getAllRecords();
    Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var record in records) {
      try {
        final createdAt = record['created_at'];
        DateTime dt;
        if (createdAt is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
        } else if (createdAt is String) {
          dt = DateTime.parse(createdAt);
        } else {
          continue;
        }
        DateTime day = DateTime(dt.year, dt.month, dt.day);
        if (!events.containsKey(day)) {
          events[day] = [];
        }
        events[day]!.add(record);
      } catch (e) {
        continue;
      }
    }

    if (mounted) {
      setState(() {
        _events = events;
        _allRecords = records;
      });
      if (_selectedDay != null) {
        _loadDayRecords(_selectedDay!);
      }
    }
  }

  Future<void> _loadDayRecords(DateTime day) async {
    final records = await _dbHelper.getRecordsByDate(day);
    if (mounted) {
      setState(() {
        _selectedDayRecords = records;
      });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
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

  Map<String, List<Map<String, dynamic>>> _getGroupedRecords() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var record in _allRecords) {
      try {
        final createdAt = record['created_at'];
        DateTime dt;
        if (createdAt is num) {
          dt = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
        } else if (createdAt is String) {
          dt = DateTime.parse(createdAt);
        } else {
          continue;
        }
        String dateKey = DateFormat('yyyy-MM-dd').format(dt);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(record);
      } catch (e) {
        continue;
      }
    }
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        DateTime getDt(Map<String, dynamic> r) {
          final t = r['created_at'];
          if (t is num) return DateTime.fromMillisecondsSinceEpoch(t.toInt());
          if (t is String) return DateTime.parse(t);
          return DateTime.now();
        }
        try {
          return getDt(a).compareTo(getDt(b));
        } catch (e) {
          return 0;
        }
      });
    }
    return grouped;
  }

  String _getDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final target = DateTime(dt.year, dt.month, dt.day);
    
    if (target == today) return '今天';
    if (target == yesterday) return '昨天';
    return DateFormat('MM月dd日 EEEE', 'zh_CN').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('日历视图', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          ToggleButtons(
            isSelected: [_viewMode == 'calendar', _viewMode == 'timeline'],
            onPressed: (index) {
              setState(() {
                _viewMode = index == 0 ? 'calendar' : 'timeline';
              });
            },
            borderRadius: BorderRadius.circular(8),
            constraints: BoxConstraints(minWidth: 56, minHeight: 36),
            color: Colors.white.withOpacity(0.7),
            selectedColor: Colors.white,
            fillColor: Theme.of(context).colorScheme.primary,
            borderColor: Colors.white.withOpacity(0.3),
            selectedBorderColor: Colors.white.withOpacity(0.5),
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 16),
                  SizedBox(width: 4),
                  Text('日历', style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline, size: 16),
                  SizedBox(width: 4),
                  Text('时间轴', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          SizedBox(width: 12),
        ],
      ),
      body: _viewMode == 'calendar' ? _buildCalendarView() : _buildTimelineView(),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        _buildCalendar(),
        Expanded(child: _buildDayRecords()),
      ],
    );
  }

  Widget _buildTimelineView() {
    final theme = Theme.of(context);
    final grouped = _getGroupedRecords();
    
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            SizedBox(height: 12),
            Text('还没有记录', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final records = grouped[dateKey]!;
        final dt = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期标题
            Padding(
              padding: EdgeInsets.only(top: index > 0 ? 16 : 8, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _getDayLabel(dt),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy/MM/dd').format(dt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${records.length}条记录',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 时间轴记录列表
            ...records.asMap().entries.map((entry) {
              final record = entry.value;
              final isLast = entry.key == records.length - 1;
              return _buildTimelineItem(record, isLast, theme);
            }),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> record, bool isLast, ThemeData theme) {
    DateTime dt;
    try {
      final createdAt = record['created_at'];
      if (createdAt is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        dt = DateTime.parse(createdAt);
      } else {
        dt = DateTime.now();
      }
    } catch (e) {
      dt = DateTime.now();
    }
    String timeStr = DateFormat('HH:mm').format(dt);
    String content = record['content']?.toString() ?? '';
    String? mood = record['mood']?.toString();
    int recordId = record['id'] ?? 0;

    List<String> tags = [];
    if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(record['tags'].toString());
        tags = decoded.map((e) => e.toString()).toList();
      } catch (e) {}
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间轴线和圆点
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getMoodColor(mood),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  color: theme.dividerColor.withOpacity(0.3),
                ),
            ],
          ),
        ),
        // 内容卡片
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecordDetailPage(recordId: recordId)),
              );
              if (result == true) {
                _loadEvents();
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getMoodIcon(mood), color: _getMoodColor(mood), size: 16),
                      SizedBox(width: 6),
                      Text(timeStr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  if (content.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.4)),
                  ],
                  if (tags.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.take(3).toList().asMap().entries.map((entry) =>
                        Chip(
                          label: Text(entry.value, style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: _getTagColor(entry.key),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadDayRecords(selectedDay);
        },
        eventLoader: _getEventsForDay,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: {CalendarFormat.month: '月'},
        locale: 'zh_CN',
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Color(0xFFFF6B6B),
            shape: BoxShape.circle,
          ),
          markerSize: 5,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
          leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
          rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          weekendStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildDayRecords() {
    final theme = Theme.of(context);
    if (_selectedDayRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            SizedBox(height: 12),
            Text('这天没有记录', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedDayRecords.length,
      itemBuilder: (context, index) {
        final record = _selectedDayRecords[index];
        int recordId = record['id'] ?? 0;
        DateTime dt;
        try {
          final createdAt = record['created_at'];
          if (createdAt is int) {
            dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
          } else if (createdAt is String) {
            dt = DateTime.parse(createdAt);
          } else {
            dt = DateTime.now();
          }
        } catch (e) {
          dt = DateTime.now();
        }
        String timeStr = DateFormat('HH:mm').format(dt);
        String content = record['content']?.toString() ?? '';
        String? mood = record['mood']?.toString();

        List<String> tags = [];
        if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
          try {
            List<dynamic> decoded = jsonDecode(record['tags'].toString());
            tags = decoded.map((e) => e.toString()).toList();
          } catch (e) {}
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.cardColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecordDetailPage(recordId: recordId)),
              );
              if (result == true) {
                _loadEvents();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getMoodIcon(mood), color: _getMoodColor(mood), size: 20),
                      SizedBox(width: 6),
                      Text(timeStr, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.4)),
                  if (tags.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.take(3).toList().asMap().entries.map((entry) =>
                        Chip(
                          label: Text(entry.value, style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: _getTagColor(entry.key),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
