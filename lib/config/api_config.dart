class ApiConfig {
  static const String deepseekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: 'sk-12dcf244168e445891d34b594b2fe799',
  );

  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1/chat/completions';

  static const String iflyAppId = String.fromEnvironment(
    'IFLY_APP_ID',
    defaultValue: '000dc3e2',
  );

  static const String iflyAppKey = String.fromEnvironment(
    'IFLY_APP_KEY',
    defaultValue: 'eeb3a079d047433a30fc7d39a2988f50',
  );

  static const String iflyAppSecret = String.fromEnvironment(
    'IFLY_APP_SECRET',
    defaultValue: 'N2IxNzU5YzNhMDI3YjQ2N2Q2MzMxNDAx',
  );
}
