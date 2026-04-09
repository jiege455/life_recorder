import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import 'record_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedDayRecords = [];

  @override
  void initState() { super.initState(); _selectedDay = _focusedDay; _loadEvents(); }

  Future<void> _loadEvents() async {
    final records = await _dbHelper.getAllRecords();
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var record in records) {
      try {
        final createdAt = record['created_at'];
        DateTime dt;
        if (createdAt is int) { dt = DateTime.fromMillisecondsSinceEpoch(createdAt); } else if (createdAt is String) { dt = DateTime.parse(createdAt); } else { continue; }
        DateTime day = DateTime(dt.year, dt.month, dt.day);
        if (!events.containsKey(day)) events[day] = [];
        events[day]!.add(record);
      } catch (e) { continue; }
    }
    if (mounted) { setState(() { _events = events; }); if (_selectedDay != null) _loadDayRecords(_selectedDay!); }
  }

  Future<void> _loadDayRecords(DateTime day) async {
    final records = await _dbHelper.getRecordsByDate(day);
    if (mounted) setState(() { _selectedDayRecords = records; });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) => _events[DateTime(day.year, day.month, day.day)] ?? [];

  IconData _getMoodIcon(String? mood) { switch (mood) { case 'happy': return Icons.sentiment_very_satisfied; case 'neutral': return Icons.sentiment_neutral; case 'sad': return Icons.sentiment_dissatisfied; case 'excited': return Icons.celebration; default: return Icons.sentiment_satisfied_alt; } }
  Color _getMoodColor(String? mood) { switch (mood) { case 'happy': return Colors.amber; case 'neutral': return Colors.grey; case 'sad': return Colors.blue; case 'excited': return Colors.pink; default: return Colors.green; } }
  Color _getTagColor(int index) { final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red]; return colors[index % colors.length]; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('日历视图', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Theme.of(context).colorScheme.primary, elevation: 0, centerTitle: true, automaticallyImplyLeading: false),
      body: Column(children: [_buildCalendar(), Expanded(child: _buildDayRecords())]),
    );
  }

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Container(
      margin: EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: TableCalendar(
        firstDay: DateTime(2024, 1, 1), lastDay: DateTime(2030, 12, 31), focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) { setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); _loadDayRecords(selectedDay); },
        eventLoader: _getEventsForDay, calendarFormat: CalendarFormat.month, availableCalendarFormats: {CalendarFormat.month: '月'}, locale: 'zh_CN',
        calendarStyle: CalendarStyle(outsideDaysVisible: false, selectedDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: primaryColor.withOpacity(0.3), shape: BoxShape.circle), markerDecoration: BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle), markerSize: 5),
        headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor), leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor), rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor)),
        daysOfWeekStyle: DaysOfWeekStyle(weekdayStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant), weekendStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
      ),
    );
  }

  Widget _buildDayRecords() {
    final theme = Theme.of(context);
    if (_selectedDayRecords.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy, size: 60, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)), SizedBox(height: 12), Text('这天没有记录', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant))]));
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16), itemCount: _selectedDayRecords.length,
      itemBuilder: (context, index) {
        final record = _selectedDayRecords[index];
        int recordId = record['id'] ?? 0;
        DateTime dt; try { final createdAt = record['created_at']; if (createdAt is int) { dt = DateTime.fromMillisecondsSinceEpoch(createdAt); } else if (createdAt is String) { dt = DateTime.parse(createdAt); } else { dt = DateTime.now(); } } catch (e) { dt = DateTime.now(); }
        String timeStr = DateFormat('HH:mm').format(dt); String content = record['content']?.toString() ?? ''; String? mood = record['mood']?.toString();
        List<String> tags = []; if (record['tags'] != null && record['tags'].toString().isNotEmpty) { try { List<dynamic> decoded = jsonDecode(record['tags'].toString()); tags = decoded.map((e) => e.toString()).toList(); } catch (e) {} }
        return Card(elevation: 0, margin: EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), color: theme.cardColor,
          child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => RecordDetailPage(recordId: recordId))); if (result == true) _loadEvents(); },
            child: Padding(padding: EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(_getMoodIcon(mood), color: _getMoodColor(mood), size: 20), SizedBox(width: 6), Text(timeStr, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant))]),
              SizedBox(height: 8), Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.4)),
              if (tags.isNotEmpty) ...[SizedBox(height: 6), Wrap(spacing: 4, runSpacing: 4, children: tags.take(3).toList().asMap().entries.map((entry) => Chip(label: Text(entry.value, style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: _getTagColor(entry.key), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact, padding: EdgeInsets.symmetric(horizontal: 6))).toList())],
            ]),
          ),
        ));
      },
    );
  }
}
