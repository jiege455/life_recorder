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
    final cardKey = GlobalKey();
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999,
        top: -9999,
        child: Material(
          child: RepaintBoundary(
            key: cardKey,
            child: _ShareCardWidget(
              content: content,
              mood: mood,
              moodEmoji: moodEmoji,
              dateStr: dateStr,
              tags: tags,
              images: images,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    await Future.delayed(Duration(milliseconds: 1500));

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        _showShareOptions(context, content: content, mood: mood, moodEmoji: moodEmoji, dateStr: dateStr, tags: tags, images: images);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        overlayEntry.remove();
        _showShareOptions(context, content: content, mood: mood, moodEmoji: moodEmoji, dateStr: dateStr, tags: tags, images: images);
        return;
      }

      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(buffer.asUint8List());

      overlayEntry.remove();

      _showShareOptionsDialog(context, filePath, content: content, mood: mood, moodEmoji: moodEmoji, dateStr: dateStr, tags: tags, images: images);
    } catch (e) {
      overlayEntry.remove();
      _showShareOptions(context, content: content, mood: mood, moodEmoji: moodEmoji, dateStr: dateStr, tags: tags, images: images);
    }
  }

  static Future<void> _generateAndShare(
    BuildContext context, {
    required String content,
    required String mood,
    required String moodEmoji,
    required String dateStr,
    required List<String> tags,
    List<String>? images,
  }) async {
    final cardKey = GlobalKey();
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999,
        top: -9999,
        child: Material(
          child: RepaintBoundary(
            key: cardKey,
            child: _ShareCardWidget(
              content: content,
              mood: mood,
              moodEmoji: moodEmoji,
              dateStr: dateStr,
              tags: tags,
              images: images,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    await Future.delayed(Duration(milliseconds: 1500));

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        await Share.share('$content\n\n—— AI人生记录器');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        overlayEntry.remove();
        await Share.share('$content\n\n—— AI人生记录器');
        return;
      }

      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(buffer.asUint8List());
      overlayEntry.remove();

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'AI人生记录器 - 记录生活点滴',
      );
    } catch (e) {
      overlayEntry.remove();
      await Share.share('$content\n\n—— AI人生记录器');
    }
  }

  static Future<void> _saveToGallery(
    BuildContext context, {
    required String content,
    required String mood,
    required String moodEmoji,
    required String dateStr,
    required List<String> tags,
    List<String>? images,
  }) async {
    final cardKey = GlobalKey();
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999,
        top: -9999,
        child: Material(
          child: RepaintBoundary(
            key: cardKey,
            child: _ShareCardWidget(
              content: content,
              mood: mood,
              moodEmoji: moodEmoji,
              dateStr: dateStr,
              tags: tags,
              images: images,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    await Future.delayed(Duration(milliseconds: 1500));

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存图片失败')));
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        overlayEntry.remove();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存图片失败')));
        return;
      }

      final buffer = byteData.buffer;
      final result = await ImageGallerySaverPlus.saveImage(
        buffer.asUint8List(),
        name: 'life_recorder_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      overlayEntry.remove();

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text('已保存到相册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('打开微信朋友圈即可选择此图片分享', style: TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存到相册失败，请检查权限')));
      }
    } catch (e) {
      overlayEntry.remove();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存图片失败: $e')));
    }
  }

  static void _showShareOptionsDialog(BuildContext context, String filePath, {
    required String content,
    required String mood,
    required String moodEmoji,
    required String dateStr,
    required List<String> tags,
    List<String>? images,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择分享方式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: Colors.blue),
              title: Text('系统分享'),
              subtitle: Text('分享到任意应用'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'AI人生记录器 - 记录生活点滴',
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green),
              title: Text('保存到相册'),
              subtitle: Text('保存后可在微信朋友圈分享'),
              onTap: () async {
                Navigator.pop(context);
                await _saveToGallery(
                  context,
                  content: content,
                  mood: mood,
                  moodEmoji: moodEmoji,
                  dateStr: dateStr,
                  tags: tags,
                  images: images,
                );
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static void _showShareOptions(BuildContext context, {
    required String content,
    required String mood,
    required String moodEmoji,
    required String dateStr,
    required List<String> tags,
    List<String>? images,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择分享方式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: Colors.blue),
              title: Text('系统分享'),
              subtitle: Text('分享到任意应用'),
              onTap: () {
                Navigator.pop(context);
                Share.share('$content\n\n—— AI人生记录器');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green),
              title: Text('生成卡片并保存到相册'),
              subtitle: Text('保存后可在微信朋友圈分享'),
              onTap: () async {
                Navigator.pop(context);
                await _saveToGallery(
                  context,
                  content: content,
                  mood: mood,
                  moodEmoji: moodEmoji,
                  dateStr: dateStr,
                  tags: tags,
                  images: images,
                );
              },
            ),
            SizedBox(height: 10),
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
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),

          // 头部信息区
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 心情表情
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(moodEmoji, style: TextStyle(fontSize: 30)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '心情：$mood',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // 分割线
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A90E2).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // 内容卡片
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: Color(0xFF333333),
              ),
            ),
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
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2).withOpacity(0.15), Color(0xFF4A90E2).withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.auto_stories, color: Colors.white, size: 18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
