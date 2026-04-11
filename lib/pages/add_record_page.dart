import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';
import '../services/tag_service.dart';
import 'tag_manager_page.dart';

class AddRecordPage extends StatefulWidget {
  final int? editRecordId;
  final String editContent;
  final String editMood;
  final List<String> editTags;
  final List<String> editImages;

  const AddRecordPage({
    super.key,
    this.editRecordId,
    this.editContent = '',
    this.editMood = 'neutral',
    this.editTags = const [],
    this.editImages = const [],
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final TextEditingController _contentController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  final SpeechService _speechService = SpeechService();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedMood = 'neutral';
  bool _isListening = false;
  bool _isRecognizing = false;
  bool _isLoading = false;
  bool _isGeneratingTags = false;
  List<String> _generatedTags = [];
  List<String> _selectedImages = [];
  List<String> _customTags = [];
  bool get _isEditMode => widget.editRecordId != null;

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '开心'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '平静'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '难过'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '兴奋'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomTags();
    _requestMicrophonePermission();
    if (_isEditMode) {
      _contentController.text = widget.editContent;
      _selectedMood = widget.editMood;
      _generatedTags = List.from(widget.editTags);
      _selectedImages = List.from(widget.editImages);
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        await Permission.microphone.request();
      }
    } catch (e) {}
  }

  void _loadCustomTags() {
    setState(() {
      _customTags = TagService.instance.customTags;
    });
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
              if (existingText.isNotEmpty) {
                _contentController.text = existingText + result;
              } else {
                _contentController.text = result;
              }
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
              SnackBar(
                content: Text('语音识别错误: $error'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
                action: error.toString().contains('密钥')
                    ? SnackBarAction(
                        label: '查看配置',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('API 密钥配置在 lib/config/api_config.dart 文件中'), backgroundColor: Colors.blue),
                          );
                        },
                      )
                    : null,
              ),
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
            _selectedImages.add(savedPath);
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

  void _removeImage(int index) {
    final imagePath = _selectedImages[index];
    setState(() {
      _selectedImages.removeAt(index);
    });
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {}
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
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
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
                _buildImageSourceOption(Icons.camera_alt, '拍照', ImageSource.camera),
                _buildImageSourceOption(Icons.photo_library, '相册', ImageSource.gallery),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
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
            child: Icon(icon, color: Color(0xFF4A90E2), size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _generateTags() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先输入内容再生成标签')),
      );
      return;
    }

    setState(() => _isGeneratingTags = true);
    try {
      final tags = await _aiService.generateTags(_contentController.text.trim());
      if (mounted) {
        setState(() {
          _generatedTags = tags;
          _isGeneratingTags = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已生成${tags.length}个标签'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingTags = false);
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('标签生成失败：$errorMsg'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: errorMsg.contains('密钥')
                ? SnackBarAction(
                    label: '查看配置',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('API 密钥配置在 lib/config/api_config.dart 文件中'), backgroundColor: Colors.blue),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  void _removeTag(int index) {
    setState(() {
      _generatedTags.removeAt(index);
    });
  }

  void _addCustomTag(String tag) {
    if (tag.trim().isNotEmpty && !_generatedTags.contains(tag.trim())) {
      setState(() {
        _generatedTags.add(tag.trim());
      });
    }
  }

  void _addNewTag(String tag) {
    if (tag.trim().isNotEmpty && !_customTags.contains(tag.trim())) {
      TagService.instance.addTag(tag.trim());
      _loadCustomTags();
      _addCustomTag(tag.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('标签 "$tag" 添加成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (_customTags.contains(tag.trim())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('标签 "$tag" 已存在'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAddTagDialog(TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加新标签'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '输入标签名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              _addNewTag(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _addNewTag(controller.text.trim());
              }
            },
            child: Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入记录内容或添加图片')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> tags = List.from(_generatedTags);

      if (tags.isEmpty && _contentController.text.trim().isNotEmpty) {
        try {
          tags = await _aiService.generateTags(_contentController.text.trim());
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('标签自动生成失败，已保存无标签记录'),
                  backgroundColor: Colors.orange),
            );
          }
        }
      }

      if (_isEditMode) {
        await _dbHelper.updateRecord(widget.editRecordId!, {
          'content': _contentController.text.trim(),
          'mood': _selectedMood,
          'tags': jsonEncode(tags),
          'images': jsonEncode(_selectedImages),
        });
      } else {
        await _dbHelper.insertRecord({
          'content': _contentController.text.trim(),
          'mood': _selectedMood,
          'tags': jsonEncode(tags),
          'images': jsonEncode(_selectedImages),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  Color _getTagColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? '编辑记录' : '添加记录',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContentInput(),
            SizedBox(height: 16),
            _buildImageSection(),
            SizedBox(height: 20),
            _buildMoodSelector(),
            SizedBox(height: 20),
            _buildVoiceButton(),
            SizedBox(height: 20),
            _buildAITagSection(),
            SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput() {
    final theme = Theme.of(context);
    return Container(
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
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        style: TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('添加图片', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
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
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant, size: 40);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
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
            Text('点击添加图片，记录图文并茂的生活', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('选择心情',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood['emoji'], style: TextStyle(fontSize: 28)),
                    SizedBox(height: 4),
                    Text(mood['label'],
                        style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVoiceButton() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTapDown: _isRecognizing ? null : (_) => _startListening(),
            onTapUp: _isListening ? (_) => _stopListening() : null,
            onTapCancel: _isListening ? () => _stopListening() : null,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 64,
              height: 64,
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
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 28,
                      color: Theme.of(context).cardColor,
                    ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            _isRecognizing ? '正在识别...' : '按住说话（需麦克风权限）',
            style: TextStyle(
              fontSize: 13,
              color: _isRecognizing ? Colors.orange : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAITagSection() {
    final theme = Theme.of(context);
    return Container(
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
              Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text('AI 智能标签',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant)),
              Spacer(),
              _isGeneratingTags
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: _generateTags,
                      icon: Icon(Icons.auto_awesome, size: 16),
                      label: Text('生成标签'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF4A90E2),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ],
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TagManagerPage()),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                  SizedBox(width: 6),
                  Text('常用标签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                  Spacer(),
                  Text('点击去管理', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
                  Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '添加自定义标签，按回车确认',
                    prefixIcon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 13),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _addNewTag(value.trim());
                    }
                  },
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TagManagerPage()),
                  );
                },
                icon: Icon(Icons.manage_search, size: 18),
                label: Text('管理'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (_generatedTags.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _generatedTags.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value,
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  backgroundColor: _getTagColor(entry.key),
                  deleteIconColor: Colors.white70,
                  onDeleted: () => _removeTag(entry.key),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ] else if (!_isGeneratingTags) ...[
            SizedBox(height: 8),
            Text('点击"生成标签"让 AI 自动为你打标签，或保存时自动生成',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('正在保存...',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              )
            : Text(_isEditMode ? '保存修改' : '保存记录',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
