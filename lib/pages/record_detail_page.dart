import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';

class RecordDetailPage extends StatefulWidget {
  final int recordId;

  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  final TextEditingController _contentController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _record;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isRecognizing = false;
  bool _isGeneratingTags = false;
  String _selectedMood = 'neutral';
  List<String> _editTags = [];
  List<String> _images = [];

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '开心'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '平静'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '难过'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '兴奋'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final record = await _dbHelper.getRecordById(widget.recordId);
    if (record != null && mounted) {
      setState(() {
        _record = record;
        _selectedMood = record['mood'] ?? 'neutral';
        _contentController.text = record['content']?.toString() ?? '';
        _editTags = [];
        if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
          try {
            List<dynamic> decoded = jsonDecode(record['tags'].toString());
            _editTags = decoded.map((e) => e.toString()).toList();
          } catch (e) {}
        }
        _images = [];
        if (record['images'] != null && record['images'].toString().isNotEmpty) {
          try {
            List<dynamic> decoded = jsonDecode(record['images'].toString());
            _images = decoded.map((e) => e.toString()).toList();
          } catch (e) {}
        }
      });
    }
  }

  Future<String?> _saveImageToAppDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'record_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
      final destPath = p.join(imagesDir.path, fileName);
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        final savedPath = await _saveImageToAppDir(image.path);
        if (savedPath != null) {
          setState(() {
            _images.add(savedPath);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('图片保存失败，请重试'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text('添加图片', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 8),
            Text('应用需要访问相机或相册权限来添加图片', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: Color(0xFF4A90E2), size: 28),
                      ),
                      SizedBox(height: 8),
                      Text('拍照', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.photo_library, color: Color(0xFF4A90E2), size: 28),
                      ),
                      SizedBox(height: 8),
                      Text('相册', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
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

  String _getMoodLabel(String? mood) {
    switch (mood) {
      case 'happy': return '开心';
      case 'neutral': return '平静';
      case 'sad': return '难过';
      case 'excited': return '兴奋';
      default: return '平静';
    }
  }

  void _startListening() async {
    if (!_isListening && !_isRecognizing) {
      String existingText = _contentController.text;
      setState(() => _isListening = true);

      _speechService.startListening(
        onResult: (result) {
          if (mounted && result.isNotEmpty) {
            setState(() {
              _isRecognizing = false;
              _contentController.text = existingText.isNotEmpty
                  ? existingText + result
                  : result;
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _isRecognizing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('语音错误: $error'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)),
            );
          }
        },
      );
    } else if (_isListening) {
      _stopListening();
    }
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
      _isRecognizing = true;
    });
  }

  Future<void> _generateTags() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先输入内容')),
      );
      return;
    }
    setState(() => _isGeneratingTags = true);
    try {
      final tags = await _aiService.generateTags(_contentController.text.trim());
      if (mounted) {
        setState(() {
          _editTags = tags;
          _isGeneratingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingTags = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标签生成失败'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeTag(int index) {
    setState(() {
      _editTags.removeAt(index);
    });
  }

  Future<void> _saveEdit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入记录内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> tags = List.from(_editTags);
      if (tags.isEmpty) {
        try {
          tags = await _aiService.generateTags(_contentController.text.trim());
        } catch (e) {}
      }

      await _dbHelper.updateRecord(widget.recordId, {
        'content': _contentController.text.trim(),
        'mood': _selectedMood,
        'tags': jsonEncode(tags),
        'images': jsonEncode(_images),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        _loadRecord();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteRecord() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这条记录吗？'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      }
    }
  }

  void _showFullImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullImageViewer(
          images: _images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_record == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: theme.colorScheme.primary),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<String> tags = [];
    if (_record!['tags'] != null && _record!['tags'].toString().isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(_record!['tags'].toString());
        tags = decoded.map((e) => e.toString()).toList();
      } catch (e) {}
    }

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(_record!['created_at'] ?? 0);
    String dateStr = DateFormat('yyyy 年 MM 月 dd 日 HH:mm').format(dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? '编辑记录' : '记录详情',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteRecord,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _isEditing ? _buildEditMode() : _buildViewMode(tags, dateStr),
      ),
    );
  }

  Widget _buildViewMode(List<String> tags, String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getMoodIcon(_record!['mood']),
                      color: _getMoodColor(_record!['mood']), size: 28),
                  SizedBox(width: 8),
                  Text(_getMoodLabel(_record!['mood']),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Text(dateStr,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500])),
                ],
              ),
              SizedBox(height: 16),
              Text(_record!['content']?.toString() ?? '',
                  style: TextStyle(fontSize: 16, height: 1.8)),
              if (_images.isNotEmpty) ...[
                SizedBox(height: 16),
                Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200]),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.image, size: 16, color: Color(0xFF4A90E2)),
                    SizedBox(width: 6),
                    Text('图片',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600], fontWeight: FontWeight.w500)),
                    SizedBox(width: 6),
                    Text('${_images.length}张',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400])),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullImage(index),
                        child: Container(
                          width: 120,
                          height: 120,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_images[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                                  child: Center(
                                    child: Icon(Icons.image, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400], size: 36),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                SizedBox(height: 16),
                Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200]),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4A90E2)),
                    SizedBox(width: 6),
                    Text('AI标签',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600], fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value,
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: _getTagColor(entry.key),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '今天发生了什么？',
              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400], fontSize: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.image, color: Color(0xFF4A90E2), size: 20),
                  SizedBox(width: 8),
                  Text('图片${_images.isNotEmpty ? " (${_images.length}张)" : ""}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[800])),
                  Spacer(),
                  TextButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: Icon(Icons.add_photo_alternate, size: 16),
                    label: Text('添加'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF4A90E2),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              if (_images.isNotEmpty) ...[
                SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_images[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.image, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400], size: 40);
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _images.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ] else ...[
                SizedBox(height: 8),
                Text('点击"添加"按钮上传图片', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400])),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moods.map((mood) {
            bool isSelected = _selectedMood == mood['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMood = mood['value'];
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood['emoji'], style: TextStyle(fontSize: 24)),
                    SizedBox(height: 4),
                    Text(mood['label'],
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 20),
                  SizedBox(width: 8),
                  Text('AI标签',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Spacer(),
                  _isGeneratingTags
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton.icon(
                          onPressed: _generateTags,
                          icon: Icon(Icons.auto_awesome, size: 16),
                          label: Text('重新生成'),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF4A90E2),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                ],
              ),
              if (_editTags.isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _editTags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value, style: TextStyle(fontSize: 13, color: Colors.white)),
                      backgroundColor: _getTagColor(entry.key),
                      deleteIconColor: Colors.white70,
                      onDeleted: () => _removeTag(entry.key),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        Column(
          children: [
            Center(
              child: GestureDetector(
                onTapDown: _isRecognizing ? null : (_) => _startListening(),
                onTapUp: _isListening ? (_) => _stopListening() : null,
                onTapCancel: _isListening ? () => _stopListening() : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecognizing
                        ? Colors.orange
                        : (_isListening ? Colors.red : Color(0xFF4A90E2)),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecognizing
                                ? Colors.orange
                                : (_isListening ? Colors.red : Color(0xFF4A90E2)))
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: _isRecognizing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 24,
                          color: Theme.of(context).cardColor,
                        ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                _isRecognizing ? '正在识别...' : '按住说话',
                style: TextStyle(
                  fontSize: 13,
                  color: _isRecognizing ? Colors.orange : Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : Text('保存修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(widget.images[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600], size: 64),
                      SizedBox(height: 16),
                      Text('图片无法加载', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500], fontSize: 16)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
