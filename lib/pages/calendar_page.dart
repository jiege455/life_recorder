import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<int, int> _recordCounts = {};
  List<Map<String, dynamic>> _selectedDayRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadMonthData();
    _loadDayRecords();
  }

  Future<void> _loadMonthData() async {
    final counts = await _dbHelper.getDailyRecordCounts(_focusedDay.year, _focusedDay.month);
    if (mounted) {
      setState(() {
        _recordCounts = counts;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDayRecords() async {
    if (_selectedDay == null) return;
    final records = await _dbHelper.getRecordsByDate(_selectedDay!);
    if (mounted) {
      setState(() {
        _selectedDayRecords = records;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('日历', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: CalendarHeader(
        focusedDay: _focusedDay,
        selectedDay: _selectedDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadDayRecords();
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _loadMonthData();
        },
        recordCounts: _recordCounts,
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
            Text('这天没有记录', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
            SizedBox(height: 4),
            Text('选择其他日期查看记录', style: TextStyle(fontSize: 13, color: Colors.grey[300])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedDayRecords.length,
      itemBuilder: (context, index) {
        var record = _selectedDayRecords[index];
        String content = record['content']?.toString() ?? '';
        int recordId = record['id'] ?? 0;
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
        String timeStr = DateFormat('HH:mm').format(dt);

        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 10),
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
                _loadMonthData();
                _loadDayRecords();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_getMoodIcon(record['mood']), color: _getMoodColor(record['mood']), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        SizedBox(height: 4),
                        Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CalendarHeader extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Map<int, int> recordCounts;

  const CalendarHeader({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.recordCounts,
  });

  @override
  State<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
    _selectedDay = widget.selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Color(0xFF4A90E2)),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                  widget.onPageChanged(_focusedDay);
                },
              ),
              Text(
                '${_focusedDay.year}年${_focusedDay.month}月',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Color(0xFF4A90E2)),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                  widget.onPageChanged(_focusedDay);
                },
              ),
            ],
          ),
        ),
        _buildWeekdayHeader(),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    int startingWeekday = firstDayOfMonth.weekday;
    int daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      final hasRecord = widget.recordCounts.containsKey(day);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
            widget.onDaySelected(date, _focusedDay);
          },
          child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF4A90E2) : (isToday ? Color(0xFF4A90E2).withOpacity(0.1) : null),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isToday ? Color(0xFF4A90E2) : Colors.grey[700]),
                  ),
                ),
                if (hasRecord)
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: dayWidgets,
      ),
    );
  }
}
