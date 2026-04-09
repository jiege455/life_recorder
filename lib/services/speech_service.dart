import 'dart:async';
import 'package:ifly_speech_recognition/ifly_speech_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
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
  Function(String)? _onResult;
  Function(String)? _onError;

  bool get isListening => _isListening;
  bool get isRecognizing => _isRecognizing;

  Future<bool> init() async {
    if (_isInitialized) return true;

    if (!ApiConfig.isIflyConfigured) {
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
      return false;
    }
  }

  Future<bool> requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return status.isGranted;
  }

  Future<void> startListening({
    required Function(String result) onResult,
    required Function(String error) onError,
  }) async {
    var hasPermission = await requestPermission();
    if (!hasPermission) {
      onError('\u9EA6\u514B\u98CE\u6743\u9650\u672A\u6388\u4E88');
      return;
    }

    if (!_isInitialized) {
      bool success = await init();
      if (!success) {
        onError('\u8BED\u97F3\u670D\u52A1\u521D\u59CB\u5316\u5931\u8D25');
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
      onError('\u542F\u52A8\u8BED\u97F3\u8BC6\u522B\u5931\u8D25: $e');
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
}
