import 'package:dio/dio.dart';

class AiService {
  static final AiService instance = AiService._();
  static const String _apiKey = 'sk-0d6bb31f5d9c4f8da83f2f5f0e2c2a8d';
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  final Dio _dio = Dio();

  AiService._();

  Future<List<String>> generateTags(String content) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '你是一个生活记录助手，根据用户的内容生成3-5个简短的中文标签，每个标签2-4个字，用逗号分隔，不要包含其他内容。例如：工作, 学习, 健康, 娱乐'
            },
            {
              'role': 'user',
              'content': content
            }
          ],
          'temperature': 0.8,
          'max_tokens': 100
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        String tagsText = responseData['choices'][0]['message']['content'];
        tagsText = tagsText.replaceAll(RegExp(r'[^\u4e00-\u9fa5a-zA-Z0-9,]'), '');
        List<String> tags = tagsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        return tags.take(5).toList();
      } else {
        throw Exception('AI服务请求失败');
      }
    } on DioException catch (e) {
      String errorMsg = '网络错误';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '网络连接超时';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '网络连接失败';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('标签生成失败');
    }
  }

  Future<String> generateReport(List<Map<String, dynamic>> records, String period) async {
    try {
      StringBuffer sb = StringBuffer();
      sb.writeln('$period生活记录：');
      for (var record in records) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
        String dateStr = '${dt.month}月${dt.day}日';
        String mood = _moodLabel(record['mood']);
        String content = record['content']?.toString() ?? '';
        String tagsStr = '';
        if (record['tags'] != null && record['tags'].toString().isNotEmpty) {
          try {
            List<dynamic> tags = jsonDecode(record['tags'].toString());
            tagsStr = ' #${tags.join(' #')}';
          } catch (e) {}
        }
        sb.writeln('$dateStr [$mood]$tagsStr');
        sb.writeln(content);
        sb.writeln('---');
      }

      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '你是一个温暖的生活助手，请根据用户的一周或一月生活记录生成一份简洁的生活报告。语气温暖友好，像朋友聊天一样。包含：1.整体感受 2.有趣的记录 3.小建议。用中文回答，段落分明，总字数控制在300字以内。'
            },
            {
              'role': 'user',
              'content': sb.toString()
            }
          ],
          'temperature': 0.8,
          'max_tokens': 800
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['choices'][0]['message']['content'];
      } else {
        throw Exception('AI服务请求失败');
      }
    } on DioException catch (e) {
      String errorMsg = '网络错误';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '网络连接超时';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '网络连接失败';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('报告生成失败');
    }
  }

  Future<String> generateAnnualReview(List<Map<String, dynamic>> records, String year, Map<String, int> moodStats) async {
    try {
      StringBuffer sb = StringBuffer();
      sb.writeln('$year年年度记录：');
      for (var record in records) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
        String dateStr = '${dt.year}年${dt.month}月${dt.day}日';
        String mood = _moodLabel(record['mood']);
        String content = record['content']?.toString() ?? '';
        sb.writeln('$dateStr [$mood]: $content');
      }
      sb.writeln('心情统计：happy开心${moodStats['happy'] ?? 0}次，neutral平静${moodStats['neutral'] ?? 0}次，sad难过${moodStats['sad'] ?? 0}次，excited兴奋${moodStats['excited'] ?? 0}次');

      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '你是一个温暖的生活助手，请根据用户的一年生活记录生成一份精美的年度回顾报告。语气温暖感人，像老朋友一样聊天。包含：1.年度整体概述 2.每个月的重要时刻 3.心情变化分析 4.对来年的展望。用中文回答，段落分明。'
            },
            {
              'role': 'user',
              'content': sb.toString()
            }
          ],
          'temperature': 0.8,
          'max_tokens': 1500
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['choices'][0]['message']['content'];
      } else {
        throw Exception('AI服务请求失败');
      }
    } on DioException catch (e) {
      String errorMsg = '网络错误';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '网络连接超时';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '网络连接失败';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('年度报告生成失败');
    }
  }

  String _moodLabel(String? mood) {
    switch (mood) {
      case 'happy': return '开心';
      case 'neutral': return '平静';
      case 'sad': return '难过';
      case 'excited': return '兴奋';
      default: return '平静';
    }
  }
}
