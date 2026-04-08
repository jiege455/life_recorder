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
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final records = await _dbHelper.getAllRecords();
    Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var record in records) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
      DateTime day = DateTime(dt.year, dt.month, dt.day);
      if (!events.containsKey(day)) {
        events[day] = [];
      }
      events[day]!.add(record);
    }

    if (mounted) {
      setState(() {
        _events = events;
      });
      _loadDayRecords(_selectedDay!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('\u65E5\u5386\u89C6\u56FE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(child: _buildDayRecords()),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: Color(0xFF4A90E2),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Color(0xFF4A90E2).withOpacity(0.3),
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
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
          leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF4A90E2)),
          rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF4A90E2)),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
          weekendStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildDayRecords() {
    if (_selectedDayRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
            SizedBox(height: 12),
            Text('\u8FD9\u5929\u6CA1\u6709\u8BB0\u5F55', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
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
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
        String timeStr = DateFormat('HH:mm').format(dt);
        String content = record['content']?.toString() ?? '';

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
          color: Colors.white,
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
                      Icon(_getMoodIcon(record['mood']), color: _getMoodColor(record['mood']), size: 20),
                      SizedBox(width: 6),
                      Text(timeStr, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
