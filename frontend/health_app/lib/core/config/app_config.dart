class AppConfig {
  const AppConfig._();

  static const defaultApiBaseUrl =
      'https://nominally-godlike-puffer.cloudpub.ru';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment(
      'AUTH_API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    ),
  );
}
