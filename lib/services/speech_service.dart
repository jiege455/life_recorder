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

  static const String _appId = '000dc3e2';
  static const String _apiKey = 'eeb3a079d047433a30fc7d39a2988f50';
  static const String _apiSecret = 'N2IxNzU5YzNhMDI3YjQ2N2Q2MzMxNDAx';

  bool get isConfigured => true;

  Future<bool> init() async {
    if (_isInitialized) return true;

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
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return status.isGranted;
  }

  Future<void> startListening({
    required Function(String result, bool isLast) onResult,
    required Function(String error) onError,
    required Function() onVolumeChanged,
  }) async {
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
          if (isLast) {
            _isListening = false;
          }
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
