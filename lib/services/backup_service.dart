import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  BackupService._();

  Future<String?> exportData() async {
    try {
      final records = await _dbHelper.getAllRecords();
      final backupData = {
        'version': '1.2.0',
        'exportTime': DateTime.now().toIso8601String(),
        'recordCount': records.length,
        'records': records,
      };

      final jsonString = jsonEncode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/life_recorder_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final backupData = jsonDecode(content);

      if (backupData['records'] == null) return false;

      final records = backupData['records'] as List;
      for (var record in records) {
        await _dbHelper.insertRecord({
          'content': record['content'],
          'mood': record['mood'],
          'tags': record['tags'],
          'images': record['images'] ?? '[]',
          'created_at': record['created_at'],
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
