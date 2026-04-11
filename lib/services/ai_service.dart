import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AiService {
  String get _apiKey => ApiConfig.deepseekApiKey;
  static const String _baseUrl = ApiConfig.deepseekBaseUrl;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 15),
  ));

  AiService();

  Future<List<String>> generateTags(String content) async {
    if (!ApiConfig.isDeepseekConfigured) {
      throw Exception('DeepSeek API密钥未配置。请前往设置 → API密钥配置，填写您的DeepSeek API密钥。');
    }
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
              'role': 'user',
              'content':
                  '请为以下内容生成3个以内的中文标签，只返回JSON数组格式，例如["工作","会议"]。不要返回其他任何文字。内容：$content'
            }
          ],
          'temperature': 0.3
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        String contentText = responseData['choices'][0]['message']['content'];
        contentText = contentText.trim();

        if (contentText.startsWith('```')) {
          int firstNewline = contentText.indexOf('\n');
          if (firstNewline != -1) {
            contentText = contentText.substring(firstNewline + 1);
          }
        }
        if (contentText.endsWith('```')) {
          contentText = contentText.substring(0, contentText.length - 3);
        }
        contentText = contentText.trim();

        int startIndex = contentText.indexOf('[');
        int endIndex = contentText.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          contentText = contentText.substring(startIndex, endIndex + 1);
        }

        List<dynamic> decoded = jsonDecode(contentText);
        return decoded.map((e) => e.toString()).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('API密钥无效或已过期，请前往设置 → API密钥配置，更新您的DeepSeek API密钥。');
      } else {
        throw Exception('AI服务请求失败(${response.statusCode})');
      }
    } on DioException catch (e) {
      String errorMsg = '网络错误';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '网络连接超时，请检查网络';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '网络连接失败，请检查网络';
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        errorMsg = 'API密钥无效或已过期，请前往设置更新密钥';
      } else if (e.response?.statusCode == 429) {
        errorMsg = 'API调用频率超限，请稍后再试';
      } else if (e.response?.statusCode == 402) {
        errorMsg = 'API余额不足，请前往DeepSeek官网充值';
      }
      throw Exception(errorMsg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('标签解析失败');
    }
  }

  Future<String> generateReport(List<Map<String, dynamic>> records, String period) async {
    if (!ApiConfig.isDeepseekConfigured) {
      throw Exception('DeepSeek API密钥未配置。请前往设置 → API密钥配置，填写您的DeepSeek API密钥。');
    }
    try {
      StringBuffer sb = StringBuffer();
      sb.writeln('$period生活记录：');
      for (var record in records) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(record['created_at'] ?? 0);
        String dateStr = '${dt.month}月${dt.day}日';
        String mood = _moodLabel(record['mood']);
        String content = record['content']?.toString() ?? '';
        sb.writeln('$dateStr [$mood]: $content');
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
              'content': '你是一个温暖的生活助手，请根据用户的生活记录生成一份温馨的生活总结报告。语气亲切自然，像朋友一样聊天。包含：1.整体心情概括 2.重点事件回顾 3.生活建议。用中文回答。'
            },
            {
              'role': 'user',
              'content': sb.toString()
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['choices'][0]['message']['content'];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('API密钥无效或已过期，请前往设置更新密钥');
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
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        errorMsg = 'API密钥无效或已过期，请前往设置更新密钥';
      } else if (e.response?.statusCode == 429) {
        errorMsg = 'API调用频率超限，请稍后再试';
      } else if (e.response?.statusCode == 402) {
        errorMsg = 'API余额不足，请前往DeepSeek官网充值';
      }
      throw Exception(errorMsg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('报告生成失败');
    }
  }

  Future<String> generateAnnualReview(List<Map<String, dynamic>> records, String year, Map<String, int> moodStats) async {
    if (!ApiConfig.isDeepseekConfigured) {
      throw Exception('DeepSeek API密钥未配置。请前往设置 → API密钥配置，填写您的DeepSeek API密钥。');
    }
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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('API密钥无效或已过期，请前往设置更新密钥');
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
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        errorMsg = 'API密钥无效或已过期，请前往设置更新密钥';
      } else if (e.response?.statusCode == 429) {
        errorMsg = 'API调用频率超限，请稍后再试';
      } else if (e.response?.statusCode == 402) {
        errorMsg = 'API余额不足，请前往DeepSeek官网充值';
      }
      throw Exception(errorMsg);
    } catch (e) {
      if (e is Exception) rethrow;
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
