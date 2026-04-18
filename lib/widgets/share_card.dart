import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
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
      constraints: BoxConstraints(minHeight: 450),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6BB3FD),
            Color(0xFF4A90E2),
            Color(0xFF2C5F8A),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景装饰 - 时钟元素
          Positioned(
            top: 20,
            right: -30,
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                size: Size(140, 140),
                painter: ClockPainter(),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          // 闪光点装饰
          Positioned(
            top: 60,
            left: 30,
            child: Icon(Icons.star, color: Colors.white.withOpacity(0.4), size: 20),
          ),
          Positioned(
            top: 140,
            right: 50,
            child: Icon(Icons.star, color: Colors.white.withOpacity(0.3), size: 16),
          ),
          // 主内容区
          Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部日期区域
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // 心情区域
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 心情表情 - 带发光效果
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          moodEmoji,
                          style: TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今日心情',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            mood,
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // 分割线
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // 内容卡片
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 100),
                  padding: EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 装饰性引号
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '"',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90E2).withOpacity(0.25),
                                height: 0.7,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              content,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.9,
                                color: Color(0xFF333333),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // 右下引号
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '"',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A90E2).withOpacity(0.2),
                            height: 0.5,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 标签区
                if (tags.isNotEmpty) ...[
                  SizedBox(height: 20),
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
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label, color: Colors.white, size: 14),
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
                  SizedBox(height: 20),
                  Container(
                    height: 95,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images!.take(3).length,
                      separatorBuilder: (context, index) => SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final imgPath = images![index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 95,
                            height: 95,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(
                                File(imgPath),
                                width: 95,
                                height: 95,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(Icons.image_outlined, color: Colors.white, size: 36),
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
                SizedBox(height: 24),
                // 底部品牌标识 - 使用APP logo
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // APP Logo 模拟 - 蓝色圆形
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF6BB3FD), Color(0xFF4A90E2)],
                            ),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 时钟刻度模拟
                              ...List.generate(12, (index) {
                                final angle = (index * 30) * 3.14159 / 180;
                                final isMainHour = index % 3 == 0;
                                return Positioned(
                                  top: isMainHour ? 2 : 3,
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: Container(
                                      width: isMainHour ? 1.5 : 1,
                                      height: isMainHour ? 5 : 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              // 中心点
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'AI人生记录器',
                          style: TextStyle(
                            fontSize: 14,
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

// 时钟装饰画笔
class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 外圆
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // 刻度
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * 3.14159 / 180;
      final isMainHour = i % 3 == 0;
      final innerRadius = isMainHour ? radius - 12 : radius - 8;

      final startOffset = Offset(
        center.dx + innerRadius * -math.sin(angle),
        center.dy + innerRadius * math.cos(angle),
      );
      final endOffset = Offset(
        center.dx + radius * -math.sin(angle),
        center.dy + radius * math.cos(angle),
      );

      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = isMainHour ? 2 : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(startOffset, endOffset, linePaint);
    }

    // 中心点
    canvas.drawCircle(
      center,
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
