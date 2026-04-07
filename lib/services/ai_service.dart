import 'dart:convert';
import 'package:dio/dio.dart';

class AiService {
  static const String _apiKey = 'sk-12dcf244168e445891d34b594b2fe799';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 15),
  ));

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
                  '\u8BF7\u4E3A\u4EE5\u4E0B\u5185\u5BB9\u751F\u62103\u4E2A\u4EE5\u5185\u7684\u4E2D\u6587\u6807\u7B7E\uFF0C\u53EA\u8FD4\u56DEJSON\u6570\u7EC4\u683C\u5F0F\uFF0C\u4F8B\u5982[\"\u5DE5\u4F5C\",\"\u4F1A\u8BAE\"]\u3002\u4E0D\u8981\u8FD4\u56DE\u5176\u4ED6\u4EFB\u4F55\u6587\u5B57\u3002\u5185\u5BB9\uFF1A$content'
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
      } else {
        throw Exception('AI\u670D\u52A1\u8BF7\u6C42\u5931\u8D25');
      }
    } on DioException catch (e) {
      String errorMsg = '\u7F51\u7EDC\u9519\u8BEF';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '\u7F51\u7EDC\u8FDE\u63A5\u8D85\u65F6\uFF0C\u8BF7\u68C0\u67E5\u7F51\u7EDC';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '\u7F51\u7EDC\u8FDE\u63A5\u5931\u8D25\uFF0C\u8BF7\u68C0\u67E5\u7F51\u7EDC';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('\u6807\u7B7E\u89E3\u6790\u5931\u8D25');
    }
  }
}
