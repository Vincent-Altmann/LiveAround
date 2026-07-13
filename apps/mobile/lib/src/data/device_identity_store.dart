import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

typedef DeviceIdProvider = Future<String> Function();

class DeviceIdentityStore {
  const DeviceIdentityStore();

  static const _deviceIdKey = 'livearound.device_id';

  Future<String?> readDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_deviceIdKey);
  }

  Future<void> saveDeviceId(String deviceId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceIdKey, deviceId);
  }

  Future<void> clearDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceIdKey);
  }

  Future<String> getOrCreateDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getString(_deviceIdKey);
    if (current != null && current.isNotEmpty) return current;

    final generated = _generateDeviceId();
    await preferences.setString(_deviceIdKey, generated);
    return generated;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final suffix = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'mobile-${suffix.join()}';
  }
}
