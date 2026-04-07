import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
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
  bool _speechAvailable = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '\u5F00\u5FC3'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '\u5E73\u9759'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '\u96BE\u8FC7'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '\u5174\u594B'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('\u9EA6\u514B\u98CE\u6743\u9650\u88AB\u62D2\u7EDD'),
            content: Text('\u8BED\u97F3\u8BC6\u522B\u9700\u8981\u9EA6\u514B\u98CE\u6743\u9650\uFF0C\u8BF7\u5728\u8BBE\u7F6E\u4E2D\u5F00\u542F'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('\u53D6\u6D88'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('\u53BB\u8BBE\u7F6E'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('\u8BED\u97F3\u8BC6\u522B\u9519\u8BEF: ${error.errorMsg}')),
          );
        }
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u8BED\u97F3\u8BC6\u522B\u4E0D\u53EF\u7528\uFF0C\u8BF7\u68C0\u67E5\u9EA6\u514B\u98CE\u6743\u9650')),
      );
      return;
    }

    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await _requestMicPermission();
      status = await Permission.microphone.status;
      if (!status.isGranted) return;
    }

    if (!_isListening) {
      String existingText = _contentController.text;
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              if (existingText.isNotEmpty) {
                _contentController.text = existingText + result.recognizedWords;
              } else {
                _contentController.text = result.recognizedWords;
              }
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            });
          }
        },
        localeId: 'zh_CN',
        listenMode: stt.ListenMode.dictation,
      );
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
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
      List<String> tags = [];
      try {
        tags = await _aiService.generateTags(_contentController.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('\u6807\u7B7E\u751F\u6210\u5931\u8D25\uFF0C\u5DF2\u4FDD\u5B58\u65E0\u6807\u7B7E\u8BB0\u5F55'),
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
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
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
            SizedBox(height: 24),
            _buildMoodSelector(),
            SizedBox(height: 24),
            _buildVoiceButton(),
            SizedBox(height: 32),
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
              width: 100,
              height: 100,
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
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          _isListening ? '\u6B63\u5728\u542C...\u70B9\u51FB\u505C\u6B62' : '\u70B9\u51FB\u5F00\u59CB\u8BED\u97F3\u8F93\u5165',
          style: TextStyle(
            fontSize: 14,
            color: _isListening ? Colors.red : Colors.grey[500],
          ),
        ),
      ],
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
                  Text('\u6B63\u5728\u4FDD\u5B58\u5E76\u751F\u6210\u6807\u7B7E...',
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
