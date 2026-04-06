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
    return await db.query(
      'records',
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
          List<String> tags = jsonDecode(record['tags'].toString());
          for (var tag in tags) {
            tagCount[tag] = (tagCount[tag] ?? 0) + 1;
          }
        } catch (e) {}
      }
    }

    if (tagCount.isEmpty) return null;

    var sortedTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.first.key;
  }
}
