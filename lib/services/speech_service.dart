import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  static final SpeechRecognitionService instance = SpeechRecognitionService._();

  SpeechRecognitionService._();

  String _appId = '000dc3e2';
  String _appKey = 'eeb3a079d047433a30fc7d39a2988f50';
  String _appSecret = 'N2IxNzU5YzNhMDI3YjQ2N2Q2MzMxNDAx';

  Function(String)? _onResult;
  Function(String)? _onError;
  bool _isListening = false;

  bool get isListening => _isListening;

  void initialize({
    required String appId,
    required String appKey,
    required String appSecret,
  }) {
    _appId = appId;
    _appKey = appKey;
    _appSecret = appSecret;
  }

  Future<bool> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (_isListening) return false;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      onError('麦克风权限被拒绝');
      return false;
    }

    _onResult = onResult;
    _onError = onError;
    _isListening = true;

    await Future.delayed(Duration(seconds: 3));
    String mockResult = _generateMockResult();
    _isListening = false;
    _onResult?.call(mockResult);

    return true;
  }

  String _generateMockResult() {
    List<String> phrases = [
      '今天天气真好',
      '吃了一顿美味的晚餐',
      '和朋友一起出去玩',
      '工作很顺利',
      '看了一部好电影',
    ];
    phrases.shuffle();
    return phrases.first;
  }

  Future<void> stopListening() async {
    _isListening = false;
    await Future.delayed(Duration(milliseconds: 500));
  }

  void dispose() {
    _onResult = null;
    _onError = null;
  }
}
