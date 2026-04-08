import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TagService {
  static final TagService instance = TagService._();
  static const String _tagsKey = 'custom_tags';
  List<String> _customTags = [];

  TagService._();

  Future<void> loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString(_tagsKey);
    if (tagsJson != null) {
      final List<dynamic> decoded = jsonDecode(tagsJson);
      _customTags = decoded.map((e) => e.toString()).toList();
    }
  }

  Future<void> saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tagsKey, jsonEncode(_customTags));
  }

  List<String> get customTags => _customTags;

  Future<void> addTag(String tag) async {
    if (tag.trim().isNotEmpty && !_customTags.contains(tag.trim())) {
      _customTags.add(tag.trim());
      await saveTags();
    }
  }

  Future<void> removeTag(String tag) async {
    _customTags.remove(tag);
    await saveTags();
  }

  Future<void> updateTag(String oldTag, String newTag) async {
    final index = _customTags.indexOf(oldTag);
    if (index != -1 && newTag.trim().isNotEmpty) {
      _customTags[index] = newTag.trim();
      await saveTags();
    }
  }
}
