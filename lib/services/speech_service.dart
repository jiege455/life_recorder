import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> init() async {
    if (_isInitialized) return _isAvailable;

    _isAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
      onError: (error) {
        _isListening = false;
      },
    );
    _isInitialized = true;
    return _isAvailable;
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
      await init();
    }

    if (!_isAvailable) {
      onError('\u8BED\u97F3\u8BC6\u522B\u4E0D\u53EF\u7528\uFF0C\u8BF7\u786E\u4FDD\u7F51\u7EDC\u7545\u901A');
      return;
    }

    _isListening = true;

    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: 'zh_CN',
      listenMode: stt.ListenMode.dictation,
      onSoundLevelChange: (level) {},
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void dispose() {
    stopListening();
  }
}
