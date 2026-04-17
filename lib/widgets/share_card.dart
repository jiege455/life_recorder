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

    // Show preview dialog
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
  bool _isProcessing = false;
  String _statusText = '';

  Future<void> _captureAndShare() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusText = '正在生成卡片...';
    });

    try {
      await Future.delayed(Duration(milliseconds: 500));
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() { _statusText = '生成失败'; _isProcessing = false; });
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() { _statusText = '生成失败'; _isProcessing = false; });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      setState(() { _isProcessing = false; });

      // Show share options
      if (!mounted) return;
      _showShareOptions(filePath);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = '生成失败: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showShareOptions(String filePath) {
    return showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('选择分享方式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.share, color: Colors.blue, size: 28),
                title: Text('系统分享', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text('分享到微信、QQ等应用'),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles(
                    [XFile(filePath)],
                    text: 'AI人生记录器 - 记录生活点滴',
                  );
                },
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.green, size: 28),
                title: Text('保存到相册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text('保存后可在微信朋友圈分享'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _saveToGallery(filePath);
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToGallery(String filePath) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusText = '正在保存到相册...';
    });

    try {
      final bytes = await File(filePath).readAsBytes();
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: 'life_recorder_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      if (!mounted) return;
      setState(() { _isProcessing = false; });

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败，请检查相册权限'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isProcessing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.image, color: Color(0xFF4A90E2)),
                  SizedBox(width: 8),
                  Text('分享卡片预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Preview
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
            // Footer buttons
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _captureAndShare,
                      icon: _isProcessing ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.share),
                      label: Text(_isProcessing ? '生成中...' : '选择分享方式'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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
          // 顶部装饰条
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          // 头部信息区
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
          // 分割线
          Container(
            height: 1,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4A90E2).withOpacity(0.3), Colors.transparent])),
          ),
          SizedBox(height: 20),
          // 内容卡片
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
          // 标签区
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
          // 图片区
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
          SizedBox(height: 24),
          // 底部标识
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Icon(Icons.auto_stories, color: Colors.white, size: 18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI人生记录器',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
