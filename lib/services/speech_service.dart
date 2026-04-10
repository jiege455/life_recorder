import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ifly_speech_recognition/ifly_speech_recognition.dart';
import '../config/api_config.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  SpeechRecognitionService? _speechService;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isRecognizing = false;

  StreamSubscription? _resultSubscription;
  StreamSubscription? _stopSubscription;

  Function(String result)? _onResult;
  Function(String error)? _onError;

  bool get isListening => _isListening;
  bool get isRecognizing => _isRecognizing;

  Future<bool> init() async {
    if (_isInitialized) return true;

    if (!ApiConfig.isIflyConfigured) {
      debugPrint('讯飞语音密钥未配置');
      return false;
    }

    try {
      _speechService = SpeechRecognitionService(
        appId: ApiConfig.iflyAppId,
        appKey: ApiConfig.iflyAppKey,
        appSecret: ApiConfig.iflyAppSecret,
      );

      await _speechService!.initRecorder();

      _resultSubscription = _speechService!.onRecordResult().listen(
        (message) {
          _isRecognizing = false;
          if (_onResult != null && message.isNotEmpty) {
            _onResult!(message);
          }
        },
        onError: (err) {
          _isRecognizing = false;
          _isListening = false;
          if (_onError != null) {
            _onError!(err.toString());
          }
        },
      );

      _stopSubscription = _speechService!.onStopRecording().listen((isAutomatic) {
        if (isAutomatic) {
          _isListening = false;
          _isRecognizing = true;
          _speechService!.speechRecognition();
        }
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('语音服务初始化失败: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      var status = await Permission.microphone.status;
      debugPrint('麦克风权限状态：$status');
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        status = await Permission.microphone.request();
        debugPrint('请求权限后状态：$status');
        return status.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('权限被永久拒绝，需要用户手动开启');
        // 不自动打开设置，让用户自己决定
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      debugPrint('请求权限失败：$e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String result) onResult,
    required Function(String error) onError,
  }) async {
    var hasPermission = await requestPermission();
    if (!hasPermission) {
      onError('麦克风权限未授予');
      return;
    }

    if (!_isInitialized) {
      bool success = await init();
      if (!success) {
        onError('语音服务初始化失败，请检查讯飞语音密钥是否正确配置。前往设置 → API密钥配置，填写您的讯飞开放平台密钥。');
        return;
      }
    }

    _onResult = onResult;
    _onError = onError;
    _isListening = true;
    _isRecognizing = false;

    try {
      await _speechService!.startRecord();
    } catch (e) {
      _isListening = false;
      onError('启动语音识别失败: $e');
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechService!.stopRecord();
        _isListening = false;
        _isRecognizing = true;
        _speechService!.speechRecognition();
      } catch (e) {
        _isListening = false;
        _isRecognizing = false;
      }
    }
  }

  void dispose() {
    _resultSubscription?.cancel();
    _stopSubscription?.cancel();
  }

  void reset() {
    _resultSubscription?.cancel();
    _stopSubscription?.cancel();
    _speechService = null;
    _isInitialized = false;
    _isListening = false;
    _isRecognizing = false;
  }
}
