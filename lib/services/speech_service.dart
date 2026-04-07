import 'package:ifly_speech_recognition/ifly_speech_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final IflySpeechRecognition _speech = IflySpeechRecognition();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  static const String _appId = 'YOUR_APP_ID';
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _apiSecret = 'YOUR_API_SECRET';

  bool get isConfigured =>
      _appId != 'YOUR_APP_ID' &&
      _apiKey != 'YOUR_API_KEY' &&
      _apiSecret != 'YOUR_API_SECRET';

  Future<bool> init() async {
    if (_isInitialized) return true;
    if (!isConfigured) return false;

    try {
      _speech.init({
        'appid': _appId,
        'api_key': _apiKey,
        'api_secret': _apiSecret,
        'language': 'zh_cn',
        'accent': 'mandarin',
        'vad_eos': 3000,
        'sample_rate': 16000,
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
    return status.isGranted;
  }

  Future<void> startListening({
    required Function(String result, bool isLast) onResult,
    required Function(String error) onError,
    required Function() onVolumeChanged,
  }) async {
    if (!isConfigured) {
      onError('\u8BF7\u5148\u914D\u7F6E\u8BAF\u98DE\u8BED\u97F3\u5BC6\u94A5');
      return;
    }

    var hasPermission = await requestPermission();
    if (!hasPermission) {
      onError('\u9EA6\u514B\u98CE\u6743\u9650\u672A\u6388\u4E88');
      return;
    }

    if (!_isInitialized) {
      bool success = await init();
      if (!success) {
        onError('\u8BED\u97F3\u8BC6\u522B\u521D\u59CB\u5316\u5931\u8D25');
        return;
      }
    }

    _isListening = true;

    try {
      _speech.startListening(
        onVolumeChanged: (volume) {
          onVolumeChanged();
        },
        onResult: (result, isLast) {
          _isListening = false;
          onResult(result, isLast);
        },
        onError: (error) {
          _isListening = false;
          onError(error);
        },
      );
    } catch (e) {
      _isListening = false;
      onError('\u542F\u52A8\u8BED\u97F3\u8BC6\u522B\u5931\u8D25: $e');
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speech.stopListening();
      } catch (e) {}
      _isListening = false;
    }
  }

  void dispose() {
    stopListening();
  }
}
