import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  BackupService._();

  Future<String?> exportData() async {
    try {
      final records = await _dbHelper.getAllRecords();
      final backupData = {
        'version': '2.0.0',
        'appName': 'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
        'exportTime': DateTime.now().toIso8601String(),
        'recordCount': records.length,
        'records': records.map((record) {
          return {
            'content': record['content'] ?? '',
            'mood': record['mood'] ?? 'neutral',
            'tags': _ensureTagsFormat(record['tags']),
            'images': _ensureImagesFormat(record['images']),
            'created_at': record['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
          };
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/life_recorder_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      await _cleanOldBackups(directory.path, timestamp);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'AI\u4EBA\u751F\u8BB0\u5F55\u5668 - \u6570\u636E\u5907\u4EFD ${DateTime.now().year}\u5E74${DateTime.now().month}\u6708${DateTime.now().day}\u65E5',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cleanOldBackups(String dirPath, int currentTimestamp) async {
    try {
      final dir = Directory(dirPath);
      final files = dir.listSync();
      for (var entity in files) {
        if (entity is File && entity.path.contains('life_recorder_backup_')) {
          final fileName = p.basename(entity.path);
          final tsStr = fileName
              .replaceAll('life_recorder_backup_', '')
              .replaceAll('.json', '');
          final ts = int.tryParse(tsStr);
          if (ts != null && ts != currentTimestamp) {
            await entity.delete();
          }
        }
      }
    } catch (e) {}
  }

  Future<Map<String, dynamic>?> readBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;
      if (result.files.first.path == null) return null;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final backupData = jsonDecode(content);

      if (backupData['records'] == null) return null;

      return {
        'recordCount':
            backupData['recordCount'] ?? (backupData['records'] as List).length,
        'exportTime': backupData['exportTime'] ?? '\u672A\u77E5',
        'version': backupData['version'] ?? '\u672A\u77E5',
        'records': backupData['records'],
      };
    } catch (e) {
      return null;
    }
  }

  Future<bool> importData(List<dynamic> records, {bool clearFirst = true}) async {
    final db = await _dbHelper.database;
    try {
      if (clearFirst) {
        await db.delete('records');
      }

      await db.transaction((txn) async {
        for (var record in records) {
          await txn.insert('records', {
            'content': record['content']?.toString() ?? '',
            'mood': record['mood']?.toString() ?? 'neutral',
            'tags': _ensureTagsFormat(record['tags']),
            'images': _ensureImagesFormat(record['images']),
            'created_at': _ensureInt(record['created_at']),
          });
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  int _ensureInt(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? DateTime.now().millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  dynamic _ensureTagsFormat(dynamic tags) {
    if (tags == null) return '[]';
    if (tags is List) return jsonEncode(tags);
    if (tags is String) {
      if (tags.isEmpty) return '[]';
      try {
        final decoded = jsonDecode(tags);
        if (decoded is List) return jsonEncode(decoded);
      } catch (e) {}
      return jsonEncode([tags]);
    }
    return '[]';
  }

  dynamic _ensureImagesFormat(dynamic images) {
    if (images == null) return '[]';
    if (images is List) return jsonEncode(images);
    if (images is String) {
      if (images.isEmpty) return '[]';
      try {
        final decoded = jsonDecode(images);
        if (decoded is List) return jsonEncode(decoded);
      } catch (e) {}
      return '[]';
    }
    return '[]';
  }
}
