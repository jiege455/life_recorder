import 'dart:convert';
import 'package:dio/dio.dart';

class AiService {
  static const String _apiKey = 'sk-4c521537a01a44aebc4a2bd9f057dde9';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  final Dio _dio = Dio();

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
        if (contentText.startsWith('```json')) {
          contentText = contentText.substring(7);
        }
        if (contentText.endsWith('```')) {
          contentText = contentText.substring(0, contentText.length - 3);
        }

        List<String> tags = jsonDecode(contentText.trim());
        return tags;
      } else {
        throw Exception('AI服务请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('生成标签失败: $e');
      rethrow;
    }
  }
}

void main() async {
  print('测试AI服务...');
  AiService aiService = AiService();
  try {
    List<String> tags = await aiService.generateTags('今天去公园散步，看到了美丽的花朵，心情非常愉快');
    print('生成的标签: $tags');
    print('AI服务测试成功！');
  } catch (e) {
    print('AI服务测试失败: $e');
  }
}
