import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final TextEditingController _contentController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  final SpeechService _speechService = SpeechService();

  String _selectedMood = 'neutral';
  bool _isListening = false;
  bool _isLoading = false;
  bool _isGeneratingTags = false;
  List<String> _generatedTags = [];

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '\u5F00\u5FC3'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '\u5E73\u9759'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '\u96BE\u8FC7'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '\u5174\u594B'},
  ];

  @override
  void initState() {
    super.initState();
    _speechService.init();
  }

  void _startListening() async {
    if (!_isListening) {
      String existingText = _contentController.text;
      setState(() => _isListening = true);

      _speechService.startListening(
        onResult: (result) {
          if (mounted && result.isNotEmpty) {
            setState(() {
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
            setState(() => _isListening = false);
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
    } else {
      _speechService.stopListening();
      setState(() => _isListening = false);
    }
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

  Future<void> _saveRecord() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u8BF7\u8F93\u5165\u8BB0\u5F55\u5185\u5BB9')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> tags = List.from(_generatedTags);

      if (tags.isEmpty) {
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

      await _dbHelper.insertRecord({
        'content': _contentController.text.trim(),
        'mood': _selectedMood,
        'tags': jsonEncode(tags),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '\u6DFB\u52A0\u8BB0\u5F55',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF4A90E2),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        style: TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('\u9009\u62E9\u5FC3\u60C5',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
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
                  color: isSelected ? Color(0xFF4A90E2) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? Color(0xFF4A90E2) : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFF4A90E2).withOpacity(0.3),
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
                            color: isSelected ? Colors.white : Colors.grey[600],
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
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _startListening,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : Color(0xFF4A90E2),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : Color(0xFF4A90E2))
                        .withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _isListening ? '\u6B63\u5728\u542C...\u70B9\u51FB\u505C\u6B62' : '\u8BAF\u98DE\u8BED\u97F3\u8F93\u5165',
          style: TextStyle(
            fontSize: 13,
            color: _isListening ? Colors.red : Colors.grey[500],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '\u56FD\u5185\u76F4\u8FDE\uFF0C\u4E0D\u9700\u8981VPN',
          style: TextStyle(fontSize: 11, color: Colors.green[400]),
        ),
      ],
    );
  }

  Widget _buildAITagSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      color: Colors.grey[800])),
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
            Text('\u70B9\u51FB\u201C\u751F\u6210\u6807\u7B7E\u201D\u8BA9AI\u81EA\u52A8\u4E3A\u4F60\u6253\u6807\u7B7E\uFF0C\u6216\u4FDD\u5B58\u65F6\u81EA\u52A8\u751F\u6210',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
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
          backgroundColor: Color(0xFF4A90E2),
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
            : Text('\u4FDD\u5B58\u8BB0\u5F55',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
