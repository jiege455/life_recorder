import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../database/database_helper.dart';
import 'add_record_page.dart';

class RecordDetailPage extends StatefulWidget {
  final int recordId;

  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _record;
  List<String> _images = [];
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final record = await _dbHelper.getRecordById(widget.recordId);
    if (record != null) {
      setState(() {
        _record = record;
        if (record['images'] != null && record['images'].toString().isNotEmpty) {
          try {
            List<dynamic> decoded = jsonDecode(record['images'].toString());
            _images = decoded.map((e) => e.toString()).toList();
          } catch (e) {}
        }
        if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
          try {
            List<dynamic> decoded = jsonDecode(record['tags'].toString());
            _tags = decoded.map((e) => e.toString()).toList();
          } catch (e) {}
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_record == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('记录详情', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: primaryColor,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final createdAt = _record!['created_at'];
    DateTime createTime;
    if (createdAt is int) {
      createTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else {
      createTime = DateTime.now();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('记录详情', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editRecord(),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _deleteRecord(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context, createTime),
            SizedBox(height: 16),
            _buildMoodCard(context),
            SizedBox(height: 16),
            _buildContentCard(context),
            if (_images.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildImagesCard(context),
            ],
            if (_tags.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildTagsCard(context),
            ],
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, DateTime createTime) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text('记录时间', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 8),
          Text(DateFormat('yyyy年MM月dd日 HH:mm:ss').format(createTime), style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final mood = _record!['mood'] as String?;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sentiment_satisfied, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text('心情', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(_getMoodIcon(mood), size: 32, color: _getMoodColor(mood)),
              SizedBox(width: 12),
              Text(_getMoodText(mood), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final content = _record!['content'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text('内容', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          Text(content, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildImagesCard(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text('图片', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImagePreview(context, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_images[index]),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image, color: theme.colorScheme.onSurfaceVariant),
                          );
                        },
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text('标签', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag, style: TextStyle(fontSize: 13, color: Colors.white)),
                backgroundColor: _getTagColor(tag),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String? mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'excited':
        return Icons.celebration;
      default:
        return Icons.sentiment_satisfied_alt;
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'happy':
        return Colors.amber;
      case 'neutral':
        return Colors.grey;
      case 'sad':
        return Colors.blue;
      case 'excited':
        return Colors.pink;
      default:
        return Colors.green;
    }
  }

  String _getMoodText(String? mood) {
    switch (mood) {
      case 'happy':
        return '开心';
      case 'neutral':
        return '平静';
      case 'sad':
        return '难过';
      case 'excited':
        return '兴奋';
      default:
        return '平静';
    }
  }

  Color _getTagColor(String tag) {
    final colors = [
      Color(0xFF64B5F6),
      Color(0xFF4DB6AC),
      Color(0xFF81C784),
      Color(0xFFFFD54F),
      Color(0xFFFF8A65),
      Color(0xFFA1887F),
      Color(0xFF90A4AE),
      Color(0xFFBA68C8),
    ];
    final index = tag.hashCode % colors.length;
    return colors[index];
  }

  void _showImagePreview(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: FileImage(File(_images[index])),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: _images[index]),
          ),
        ),
      ),
    );
  }

  Future<void> _editRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecordPage(
          editRecordId: widget.recordId,
          editContent: _record?['content']?.toString() ?? '',
          editMood: _record?['mood']?.toString() ?? 'neutral',
          editTags: _tags,
          editImages: _images,
        ),
      ),
    );
    if (result == true) {
      _loadRecord();
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这条记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteRecord(widget.recordId);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记录已删除')),
        );
      }
    }
  }
}
