import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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
        await Share.share('$content\n\n\u2014\u2014 AI\u4EBA\u751F\u8BB0\u5F55\u5668');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        overlayEntry.remove();
        await Share.share('$content\n\n\u2014\u2014 AI\u4EBA\u751F\u8BB0\u5F55\u5668');
        return;
      }

      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(buffer.asUint8List());

      overlayEntry.remove();

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'AI\u4EBA\u751F\u8BB0\u5F55\u5668 - \u8BB0\u5F55\u751F\u6D3B\u70B9\u6EF4',
      );
    } catch (e) {
      overlayEntry.remove();
      await Share.share('$content\n\n\u2014\u2014 AI\u4EBA\u751F\u8BB0\u5F55\u5668');
    }
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
    // 分享卡片固定使用浅色背景，确保生成图片效果一致
    return Container(
      width: 375,
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Text(
                      moodEmoji,
                      style: TextStyle(fontSize: 28),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '\u5FC3\u60C5\uFF1A$mood',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Color(0xFF333333),
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.take(5).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                        borderRadius: BorderRadius.circular(8),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.broken_image, color: Colors.grey[400], size: 28),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.auto_stories, color: Colors.white, size: 16),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI\u4EBA\u751F\u8BB0\u5F55\u5668',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                      ),
                      Text(
                        '\u5F00\u53D1\u8005\uFF1A\u6770\u54E5\u7F51\u7EDC\u79D1\u6280',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\u957F\u6309\u4FDD\u5B58\u56FE\u7247\u5206\u4EAB',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
