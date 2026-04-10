import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _deepseekKeyPref = 'deepseek_api_key';
  static const String _iflyAppIdPref = 'ifly_app_id';
  static const String _iflyAppKeyPref = 'ifly_app_key';
  static const String _iflyAppSecretPref = 'ifly_app_secret';

  static const String _defaultDeepseekApiKey = 'sk-4c521537a01a44aebc4a2bd9f057dde9';
  static const String _defaultDeepseekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String _defaultIflyAppId = '000dc3e2';
  static const String _defaultIflyAppKey = 'eeb3a079d047433a30fc7d39a2988f50';
  static const String _defaultIflyAppSecret = 'N2IxNzU5YzNhMDI3YjQ2N2Q2MzMxNDAx';

  static String _deepseekApiKey = _defaultDeepseekApiKey;
  static String _iflyAppId = _defaultIflyAppId;
  static String _iflyAppKey = _defaultIflyAppKey;
  static String _iflyAppSecret = _defaultIflyAppSecret;

  static String get deepseekApiKey => _deepseekApiKey;
  static String get deepseekBaseUrl => _defaultDeepseekBaseUrl;
  static String get iflyAppId => _iflyAppId;
  static String get iflyAppKey => _iflyAppKey;
  static String get iflyAppSecret => _iflyAppSecret;

  static bool get isDeepseekConfigured => _deepseekApiKey.isNotEmpty;
  static bool get isIflyConfigured =>
      _iflyAppId.isNotEmpty && _iflyAppKey.isNotEmpty && _iflyAppSecret.isNotEmpty;

  static bool get isUsingDefaultDeepseekKey => _deepseekApiKey == _defaultDeepseekApiKey;
  static bool get isUsingDefaultIflyKey =>
      _iflyAppId == _defaultIflyAppId &&
      _iflyAppKey == _defaultIflyAppKey &&
      _iflyAppSecret == _defaultIflyAppSecret;

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _deepseekApiKey = prefs.getString(_deepseekKeyPref) ?? _defaultDeepseekApiKey;
    _iflyAppId = prefs.getString(_iflyAppIdPref) ?? _defaultIflyAppId;
    _iflyAppKey = prefs.getString(_iflyAppKeyPref) ?? _defaultIflyAppKey;
    _iflyAppSecret = prefs.getString(_iflyAppSecretPref) ?? _defaultIflyAppSecret;
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
    _deepseekApiKey = _defaultDeepseekApiKey;
    _iflyAppId = _defaultIflyAppId;
    _iflyAppKey = _defaultIflyAppKey;
    _iflyAppSecret = _defaultIflyAppSecret;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deepseekKeyPref);
    await prefs.remove(_iflyAppIdPref);
    await prefs.remove(_iflyAppKeyPref);
    await prefs.remove(_iflyAppSecretPref);
  }
}
