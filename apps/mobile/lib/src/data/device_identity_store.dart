import 'package:shared_preferences/shared_preferences.dart';

typedef TokenProvider = Future<String?> Function();

/// Conserve la session issue de l'API : le jeton d'acces signe (JWT) et
/// l'identifiant de compte associe. L'identite n'est plus un simple
/// device-id genere localement, elle provient toujours du login/register.
class DeviceIdentityStore {
  const DeviceIdentityStore();

  static const _deviceIdKey = 'livearound.auth_session_device_id';
  static const _tokenKey = 'livearound.auth_session_token';

  Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<void> saveSession({
    required String deviceId,
    required String token,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceIdKey, deviceId);
    await preferences.setString(_tokenKey, token);
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceIdKey);
    await preferences.remove(_tokenKey);
  }
}
