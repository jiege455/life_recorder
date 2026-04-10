import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _deepseekKeyPref = 'deepseek_api_key';
  static const String _iflyAppIdPref = 'ifly_app_id';
  static const String _iflyAppKeyPref = 'ifly_app_key';
  static const String _iflyAppSecretPref = 'ifly_app_secret';

  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';

  static String _deepseekApiKey = '';
  static String _iflyAppId = '';
  static String _iflyAppKey = '';
  static String _iflyAppSecret = '';

  static String get deepseekApiKey => _deepseekApiKey;
  static String get iflyAppId => _iflyAppId;
  static String get iflyAppKey => _iflyAppKey;
  static String get iflyAppSecret => _iflyAppSecret;

  static bool get isDeepseekConfigured => _deepseekApiKey.isNotEmpty;
  static bool get isIflyConfigured =>
      _iflyAppId.isNotEmpty && _iflyAppKey.isNotEmpty && _iflyAppSecret.isNotEmpty;

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _deepseekApiKey = prefs.getString(_deepseekKeyPref) ?? '';
    _iflyAppId = prefs.getString(_iflyAppIdPref) ?? '';
    _iflyAppKey = prefs.getString(_iflyAppKeyPref) ?? '';
    _iflyAppSecret = prefs.getString(_iflyAppSecretPref) ?? '';
  }

  static Future<void> setDeepseekApiKey(String key) async {
    _deepseekApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deepseekKeyPref, key);
  }

  static Future<void> setIflyConfig({
    required String appId,
    required String appKey,
    required String appSecret,
  }) async {
    _iflyAppId = appId;
    _iflyAppKey = appKey;
    _iflyAppSecret = appSecret;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_iflyAppIdPref, appId);
    await prefs.setString(_iflyAppKeyPref, appKey);
    await prefs.setString(_iflyAppSecretPref, appSecret);
  }

  static Future<void> resetToDefaults() async {
    _deepseekApiKey = '';
    _iflyAppId = '';
    _iflyAppKey = '';
    _iflyAppSecret = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deepseekKeyPref);
    await prefs.remove(_iflyAppIdPref);
    await prefs.remove(_iflyAppKeyPref);
    await prefs.remove(_iflyAppSecretPref);
  }
}
