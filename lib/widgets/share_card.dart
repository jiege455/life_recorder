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
      constraints: BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
            Color(0xFFF093FB),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 背景装饰圆
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // 主内容区
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部栏 - 日期和心情
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    // 心情表情 - 大圆形背景
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(moodEmoji, style: TextStyle(fontSize: 26)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // 心情文字
                Text(
                  '今日心情：$mood',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 24),
                // 内容卡片 - 白色圆角
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 120),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 装饰引号
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA).withOpacity(0.3),
                              height: 0.8,
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              content,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: Color(0xFF333333),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 标签区
                if (tags.isNotEmpty) ...[
                  SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tags.take(5).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label_outline, color: Colors.white, size: 12),
                            SizedBox(width: 5),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // 图片区
                if (images != null && images!.isNotEmpty) ...[
                  SizedBox(height: 18),
                  Container(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images!.take(3).length,
                      separatorBuilder: (context, index) => SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final imgPath = images![index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(imgPath),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.image, color: Colors.white, size: 32),
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
                SizedBox(height: 20),
                // 底部标识 - 居中
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_stories,
                            color: Color(0xFF667EEA),
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'AI人生记录器',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
