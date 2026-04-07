import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../services/ai_service.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();

  Map<String, dynamic>? _record;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isGeneratingTags = false;
  bool _speechAvailable = false;
  String _selectedMood = 'neutral';
  List<String> _editTags = [];

  List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'emoji': '\u{1F60A}', 'label': '\u5F00\u5FC3'},
    {'value': 'neutral', 'emoji': '\u{1F610}', 'label': '\u5E73\u9759'},
    {'value': 'sad', 'emoji': '\u{1F622}', 'label': '\u96BE\u8FC7'},
    {'value': 'excited', 'emoji': '\u{1F389}', 'label': '\u5174\u594B'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecord();
    _initSpeech();
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
          String errorMsg = error.errorMsg == 'error_network'
              ? '\u8BED\u97F3\u8BC6\u522B\u9700\u8981\u7F51\u7EDC\u8FDE\u63A5'
              : '\u8BED\u97F3\u8BC6\u522B\u9519\u8BEF: ${error.errorMsg}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
          );
        }
      },
    );
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
      });
    }
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
      case 'happy': return '\u5F00\u5FC3';
      case 'neutral': return '\u5E73\u9759';
      case 'sad': return '\u96BE\u8FC7';
      case 'excited': return '\u5174\u594B';
      default: return '\u5E73\u9759';
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u8BED\u97F3\u8BC6\u522B\u4E0D\u53EF\u7528')),
      );
      return;
    }
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) return;

    if (!_isListening) {
      String existingText = _contentController.text;
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _contentController.text = existingText.isNotEmpty
                  ? existingText + result.recognizedWords
                  : result.recognizedWords;
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

  Future<void> _generateTags() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u8BF7\u5148\u8F93\u5165\u5185\u5BB9')),
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
          SnackBar(content: Text('\u6807\u7B7E\u751F\u6210\u5931\u8D25'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('\u8BF7\u8F93\u5165\u8BB0\u5F55\u5185\u5BB9')),
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
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        _loadRecord();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u4FDD\u5B58\u6210\u529F'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u4FDD\u5B58\u5931\u8D25'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteRecord() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\u786E\u8BA4\u5220\u9664'),
        content: Text('\u786E\u5B9A\u8981\u5220\u9664\u8FD9\u6761\u8BB0\u5F55\u5417\uFF1F'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('\u53D6\u6D88'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('\u5220\u9664', style: TextStyle(color: Colors.red)),
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
    if (_record == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Color(0xFF4A90E2)),
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
    String dateStr = DateFormat('yyyy\u5E74MM\u6708dd\u65E5 HH:mm').format(dateTime);

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditing ? '\u7F16\u8F91\u8BB0\u5F55' : '\u8BB0\u5F55\u8BE6\u60C5',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF4A90E2),
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
                  Icon(_getMoodIcon(_record!['mood']),
                      color: _getMoodColor(_record!['mood']), size: 28),
                  SizedBox(width: 8),
                  Text(_getMoodLabel(_record!['mood']),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Text(dateStr,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
              SizedBox(height: 16),
              Text(_record!['content']?.toString() ?? '',
                  style: TextStyle(fontSize: 16, height: 1.8)),
              if (tags.isNotEmpty) ...[
                SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4A90E2)),
                    SizedBox(width: 6),
                    Text('AI\u6807\u7B7E',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                  color: isSelected ? Color(0xFF4A90E2) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? Color(0xFF4A90E2) : Colors.grey[300]!,
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
                            color: isSelected ? Colors.white : Colors.grey[600],
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 20),
                  SizedBox(width: 8),
                  Text('AI\u6807\u7B7E',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Spacer(),
                  _isGeneratingTags
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton.icon(
                          onPressed: _generateTags,
                          icon: Icon(Icons.auto_awesome, size: 16),
                          label: Text('\u91CD\u65B0\u751F\u6210'),
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
        Center(
          child: GestureDetector(
            onTap: _startListening,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : Color(0xFF4A90E2),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                      SizedBox(width: 12),
                      Text('\u4FDD\u5B58\u4E2D...', style: TextStyle(color: Colors.white)),
                    ],
                  )
                : Text('\u4FDD\u5B58\u4FEE\u6539',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
              });
              _loadRecord();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('\u53D6\u6D88\u7F16\u8F91', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
      ],
    );
  }
}
