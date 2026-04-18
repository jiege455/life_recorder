import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class ShareCardHelper {
  static Future<void> shareAsImage(
    BuildContext context, {
    required String content,
    required String mood,
    required String moodEmoji,
    required String dateStr,
    required List<String> tags,
    List<String>? images,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _SharePreviewDialog(
        content: content,
        mood: mood,
        moodEmoji: moodEmoji,
        dateStr: dateStr,
        tags: tags,
        images: images,
      ),
    );
  }
}

class _SharePreviewDialog extends StatefulWidget {
  final String content;
  final String mood;
  final String moodEmoji;
  final String dateStr;
  final List<String> tags;
  final List<String>? images;

  const _SharePreviewDialog({
    required this.content,
    required this.mood,
    required this.moodEmoji,
    required this.dateStr,
    required this.tags,
    this.images,
  });

  @override
  State<_SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<_SharePreviewDialog> {
  final GlobalKey _cardKey = GlobalKey();
  String? _generatedFilePath;
  bool _isProcessing = false;
  String _statusText = '';

  Future<void> _generateCard() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusText = '正在生成卡片...';
    });

    try {
      await Future.delayed(Duration(milliseconds: 300));
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() { _statusText = '生成失败，请重试'; _isProcessing = false; });
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() { _statusText = '生成失败，请重试'; _isProcessing = false; });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      setState(() {
        _generatedFilePath = filePath;
        _isProcessing = false;
        _statusText = '卡片已生成 ✓';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = '生成失败: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (_generatedFilePath == null) {
      await _generateCard();
      if (_generatedFilePath == null) return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusText = '正在保存到相册...';
    });

    try {
      final bytes = await File(_generatedFilePath!).readAsBytes();
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: 'life_recorder_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      if (!mounted) return;
      setState(() { _isProcessing = false; _statusText = ''; });

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('已保存到相册', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('打开微信朋友圈即可选择此图片', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败，请在设置中开启相册权限'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isProcessing = false; _statusText = '保存失败'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareSystem() async {
    if (_generatedFilePath == null) {
      await _generateCard();
      if (_generatedFilePath == null) return;
    }

    setState(() { _isProcessing = true; _statusText = '正在分享...'; });

    try {
      await Share.shareXFiles(
        [XFile(_generatedFilePath!)],
        text: 'AI人生记录器 - 记录生活点滴',
      );
      if (mounted) setState(() { _isProcessing = false; _statusText = ''; });
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; _statusText = '分享失败'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Dialog(
      backgroundColor: isDark ? Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.image, color: Color(0xFF4A90E2)),
                  SizedBox(width: 8),
                  Text('分享卡片预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _ShareCardWidget(
                    content: widget.content,
                    mood: widget.mood,
                    moodEmoji: widget.moodEmoji,
                    dateStr: widget.dateStr,
                    tags: widget.tags,
                    images: widget.images,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  if (_statusText.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        _statusText,
                        style: TextStyle(
                          color: _isProcessing ? Colors.blue : (_statusText.contains('失败') ? Colors.red : Colors.green),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _shareSystem,
                          icon: _isProcessing && _generatedFilePath == null
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.share, size: 18),
                          label: Text('系统分享'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Color(0xFF4A90E2),
                            side: BorderSide(color: Color(0xFF4A90E2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _saveToGallery,
                          icon: _isProcessing && _generatedFilePath != null
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.download, size: 18),
                          label: Text('保存到相册'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCardWidget extends StatelessWidget {
  final String content;
  final String mood;
  final String moodEmoji;
  final String dateStr;
  final List<String> tags;
  final List<String>? images;

  const _ShareCardWidget({
    required this.content,
    required this.mood,
    required this.moodEmoji,
    required this.dateStr,
    required this.tags,
    this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFF0F2F5),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Center(child: Text(moodEmoji, style: TextStyle(fontSize: 30))),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
                    SizedBox(height: 6),
                    Text('心情：$mood', style: TextStyle(fontSize: 15, color: Color(0xFF333333), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 1,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4A90E2).withOpacity(0.3), Colors.transparent])),
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Text(content, style: TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF333333))),
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.take(5).map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF4A90E2).withOpacity(0.15), Color(0xFF4A90E2).withOpacity(0.05)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.2), width: 1),
                  ),
                  child: Text('#$tag', style: TextStyle(fontSize: 13, color: Color(0xFF4A90E2), fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],
          if (images != null && images!.isNotEmpty) ...[
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images!.take(3).map((imgPath) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imgPath),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 28),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 16),
          Center(
            child: Text(
              'AI人生记录器',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }
}
