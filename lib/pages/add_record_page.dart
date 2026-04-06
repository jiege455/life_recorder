import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import '../database/database_helper.dart';
import '../services/ai_service.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final TextEditingController _contentController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiService _aiService = AiService();

  String _selectedMood = 'neutral';
  bool _isListening = false;
  bool _isLoading = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '😊', 'label': '开心'},
    {'value': 'neutral', 'emoji': '😐', 'label': '平静'},
    {'value': 'sad', 'emoji': '😢', 'label': '难过'},
    {'value': 'excited', 'emoji': '🎉', 'label': '兴奋'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('语音识别错误: \${error.errorMsg}')),
        );
      },
    );
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _contentController.text = result.recognizedWords;
            });
          },
          localeId: 'zh_CN',
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _saveRecord() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入记录内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> tags = [];
      try {
        tags = await _aiService.generateTags(_contentController.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('标签生成失败，已保存无标签记录'),
                backgroundColor: Colors.orange),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 记录保存成功！'),
            backgroundColor: Color(0xFF50C878),
          ),
        );
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
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '添加记录',
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
      body: Column(
        children: [
          _buildDeveloperInfo(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentInput(),
                  SizedBox(height: 24),
                  _buildMoodSelector(),
                  SizedBox(height: 24),
                  _buildVoiceButton(),
                  SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderBottom: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '开发者：杰哥网络科技',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            'qq2711793818',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
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
          hintText: '今天发生了什么？',
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
          child: Text('选择心情',
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
    return Center(
      child: GestureDetector(
        onTap: _startListening,
        child: Container(
          width: 120,
          height: 120,
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
            size: 48,
            color: Colors.white,
          ),
        ),
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
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('保存记录',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }
}
