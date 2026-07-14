class LiveAroundConfig {
  const LiveAroundConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'LIVEAROUND_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Mode demonstration : l'application fonctionne entierement sur des
  /// donnees mock, sans API. A activer explicitement :
  /// flutter run --dart-define LIVEAROUND_DEMO_MODE=true
  static const demoMode = bool.fromEnvironment('LIVEAROUND_DEMO_MODE');
}
