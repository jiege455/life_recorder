class ApiConfig {
  static const String deepseekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );

  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';

  static const String iflyAppId = String.fromEnvironment(
    'IFLY_APP_ID',
    defaultValue: '',
  );

  static const String iflyAppKey = String.fromEnvironment(
    'IFLY_APP_KEY',
    defaultValue: '',
  );

  static const String iflyAppSecret = String.fromEnvironment(
    'IFLY_APP_SECRET',
    defaultValue: '',
  );

  static bool get isDeepseekConfigured => deepseekApiKey.isNotEmpty;
  static bool get isIflyConfigured => iflyAppId.isNotEmpty && iflyAppKey.isNotEmpty && iflyAppSecret.isNotEmpty;
}
