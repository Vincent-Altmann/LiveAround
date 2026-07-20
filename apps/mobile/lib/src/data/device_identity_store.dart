import 'package:shared_preferences/shared_preferences.dart';

typedef TokenProvider = Future<String?> Function();

/// Conserve la session issue de l'API : jeton d'acces court (JWT 7 j),
/// refresh token rotatif (90 j) et identifiant de compte. L'identite
/// provient toujours du login/register, jamais d'un identifiant local.
class DeviceIdentityStore {
  const DeviceIdentityStore();

  static const _deviceIdKey = 'livearound.auth_session_device_id';
  static const _tokenKey = 'livearound.auth_session_token';
  static const _refreshTokenKey = 'livearound.auth_session_refresh_token';

  Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<String?> readRefreshToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_refreshTokenKey);
  }

  Future<void> saveSession({
    required String deviceId,
    required String token,
    String? refreshToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceIdKey, deviceId);
    await preferences.setString(_tokenKey, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await preferences.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceIdKey);
    await preferences.remove(_tokenKey);
    await preferences.remove(_refreshTokenKey);
  }
}
