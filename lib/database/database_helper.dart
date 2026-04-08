import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('life_recorder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        mood TEXT,
        tags TEXT,
        created_at INTEGER
      )
    ''');
  }

  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('records', record);
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await database;
    return await db.query('records', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getRecordById(int id) async {
    final db = await database;
    final results = await db.query('records', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateRecord(int id, Map<String, dynamic> record) async {
    final db = await database;
    return await db.update('records', record, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchRecords(String keyword) async {
    final db = await database;
    return await db.query(
      'records',
      where: 'content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getThisWeekCount() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    final weekAgoTimestamp = weekAgo.millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM records WHERE created_at >= ?',
      [weekAgoTimestamp],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<String?> getMostUsedTag() async {
    final db = await database;
    final records = await db.query('records', columns: ['tags']);
    Map<String, int> tagCount = {};
    for (var record in records) {
      if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
        try {
          List<dynamic> tags = jsonDecode(record['tags'].toString());
          for (var tag in tags) {
            String tagStr = tag.toString();
            tagCount[tagStr] = (tagCount[tagStr] ?? 0) + 1;
          }
        } catch (e) {}
      }
    }
    if (tagCount.isEmpty) return null;
    var sortedTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedTags.first.key;
  }

  Future<List<Map<String, dynamic>>> getRecordsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return await db.query(
      'records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, int>> getMoodStats() async {
    final db = await database;
    final result = await db.rawQuery('SELECT mood, COUNT(*) as count FROM records GROUP BY mood');
    Map<String, int> stats = {};
    for (var row in result) {
      String mood = row['mood']?.toString() ?? 'neutral';
      stats[mood] = (row['count'] as int?) ?? 0;
    }
    return stats;
  }

  Future<Map<int, int>> getDailyRecordCounts(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final records = await db.query(
      'records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      columns: ['created_at'],
    );
    Map<int, int> counts = {};
    for (var record in records) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] as int);
      counts[dt.day] = (counts[dt.day] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<double>> getMonthlyMoodCounts(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final records = await db.query(
      'records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      columns: ['mood', 'created_at'],
    );
    int daysInMonth = DateTime(year, month + 1, 0).day;
    List<double> counts = List.filled(daysInMonth, 0);
    for (var record in records) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] as int);
      int moodValue = _moodToValue(record['mood']?.toString());
      counts[dt.day - 1] = moodValue.toDouble();
    }
    return counts;
  }

  int _moodToValue(String? mood) {
    switch (mood) {
      case 'happy': return 4;
      case 'excited': return 3;
      case 'neutral': return 2;
      case 'sad': return 1;
      default: return 2;
    }
  }

  Future<List<Map<String, dynamic>>> getRecordsForPeriod(DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at ASC',
    );
  }
}
