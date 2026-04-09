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
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '\u5F00\u5FC3'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '\u5E73\u9759'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '\u96BE\u8FC7'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '\u5174\u594B'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomTags();
    if (_isEditMode) {
      _contentController.text = widget.editContent;
      _selectedMood = widget.editMood;
      _generatedTags = List.from(widget.editTags);
      _selectedImages = List.from(widget.editImages);
    }
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
                content: Text('\u8BED\u97F3\u8BC6\u522B\u9519\u8BEF: $error'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
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
              SnackBar(content: Text('\u56FE\u7247\u4FDD\u5B58\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u9009\u62E9\u56FE\u7247\u5931\u8D25'), backgroundColor: Colors.red),
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
            Text('\u6DFB\u52A0\u56FE\u7247', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 8),
            Text('\u5E94\u7528\u9700\u8981\u8BBF\u95EE\u76F8\u673A\u6216\u76F8\u518C\u6743\u9650\u6765\u6DFB\u52A0\u56FE\u7247', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(Icons.camera_alt, '\u62CD\u7167', ImageSource.camera),
                _buildImageSourceOption(Icons.photo_library, '\u76F8\u518C', ImageSource.gallery),
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
        SnackBar(content: Text('\u8BF7\u5148\u8F93\u5165\u5185\u5BB9\u518D\u751F\u6210\u6807\u7B7E')),
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
            content: Text('\u5DF2\u751F\u6210${tags.length}\u4E2A\u6807\u7B7E'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingTags = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u6807\u7B7E\u751F\u6210\u5931\u8D25\uFF1A$e'),
            backgroundColor: Colors.red,
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

  Future<void> _saveRecord() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u8BF7\u8F93\u5165\u8BB0\u5F55\u5185\u5BB9\u6216\u6DFB\u52A0\u56FE\u7247')),
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
                  content: Text('\u6807\u7B7E\u81EA\u52A8\u751F\u6210\u5931\u8D25\uFF0C\u5DF2\u4FDD\u5B58\u65E0\u6807\u7B7E\u8BB0\u5F55'),
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
            content: Text('\u4FDD\u5B58\u5931\u8D25\uFF0C\u8BF7\u91CD\u8BD5'),
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
          _isEditMode ? '\u7F16\u8F91\u8BB0\u5F55' : '\u6DFB\u52A0\u8BB0\u5F55',
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
          hintText: '\u4ECA\u5929\u53D1\u751F\u4E86\u4EC0\u4E48\uFF1F',
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
              Text('\u6DFB\u52A0\u56FE\u7247', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              Spacer(),
              TextButton.icon(
                onPressed: _showImageSourceDialog,
                icon: Icon(Icons.add_photo_alternate, size: 16),
                label: Text('\u6DFB\u52A0'),
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
            Text('\u70B9\u51FB\u6DFB\u52A0\u56FE\u7247\uFF0C\u8BB0\u5F55\u56FE\u6587\u5E76\u8302\u7684\u751F\u6D3B', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
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
          child: Text('\u9009\u62E9\u5FC3\u60C5',
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
            _isRecognizing ? '\u6B63\u5728\u8BC6\u522B...' : '\u6309\u4F4F\u8BF4\u8BDD\uFF08\u9700\u9EA6\u514B\u98CE\u6743\u9650\uFF09',
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
              Text('AI\u667A\u80FD\u6807\u7B7E',
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
                      label: Text('\u751F\u6210\u6807\u7B7E'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF4A90E2),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ],
          ),
          if (_customTags.isNotEmpty) ...[
            SizedBox(height: 8),
            Text('\u5E38\u7528\u6807\u7B7E\uFF1A', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _customTags.map((tag) {
                final isSelected = _generatedTags.contains(tag);
                return GestureDetector(
                  onTap: isSelected ? null : () => _addCustomTag(tag),
                  child: Chip(
                    label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : theme.colorScheme.onSurface)),
                    backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ],
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
            Text('\u70B9\u51FB\u201C\u751F\u6210\u6807\u7B7E\u201D\u8BA9 AI \u81EA\u52A8\u4E3A\u4F60\u6253\u6807\u7B7E\uFF0C\u6216\u4FDD\u5B58\u65F6\u81EA\u52A8\u751F\u6210',
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
                  Text('\u6B63\u5728\u4FDD\u5B58...',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              )
            : Text(_isEditMode ? '\u4FDD\u5B58\u4FEE\u6539' : '\u4FDD\u5B58\u8BB0\u5F55',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
