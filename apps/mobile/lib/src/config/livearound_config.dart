class LiveAroundConfig {
  const LiveAroundConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'LIVEAROUND_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
