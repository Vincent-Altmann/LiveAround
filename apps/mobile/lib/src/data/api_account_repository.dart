import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/concert.dart';
import '../domain/user_profile.dart';
import 'account_repository.dart';
import 'device_identity_store.dart';
import 'mock_account_repository.dart';

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository({
    required String baseUrl,
    required DeviceIdentityStore identityStore,
    AccountRepository? fallbackRepository,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl),
        _identityStore = identityStore,
        _fallbackRepository = fallbackRepository ?? MockAccountRepository(),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final DeviceIdentityStore _identityStore;
  final AccountRepository _fallbackRepository;
  final http.Client _client;

  @override
  Future<UserProfile?> restoreSession() async {
    final deviceId = await _identityStore.readDeviceId();
    if (deviceId == null || deviceId.isEmpty) return null;

    try {
      final payload = await _getJson(_buildUri('/users/me'));
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.restoreSession();
    }
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _postJson(
        _buildUri('/auth/login'),
        body: {'email': email.trim(), 'password': password},
        includeDeviceId: false,
      );
      return _saveAuthSession(payload as Map<String, dynamic>);
    } catch (error) {
      if (error is ApiRequestException && error.isClientError) rethrow;
      return _fallbackRepository.login(email: email, password: password);
    }
  }

  @override
  Future<UserProfile> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _postJson(
        _buildUri('/auth/register'),
        body: {
          'displayName': displayName.trim(),
          'email': email.trim(),
          'password': password,
        },
        includeDeviceId: false,
      );
      return _saveAuthSession(payload as Map<String, dynamic>);
    } catch (error) {
      if (error is ApiRequestException && error.isClientError) rethrow;
      return _fallbackRepository.register(
        displayName: displayName,
        email: email,
        password: password,
      );
    }
  }

  @override
  Future<UserProfile> loadProfile() async {
    try {
      final deviceId = await _identityStore.getOrCreateDeviceId();
      final payload = await _postJson(
        _buildUri('/users/me'),
        body: {'deviceId': deviceId},
      );
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.loadProfile();
    }
  }

  @override
  Future<UserProfile> saveProfile({
    required String displayName,
    required String email,
  }) async {
    try {
      final deviceId = await _identityStore.getOrCreateDeviceId();
      final payload = await _postJson(
        _buildUri('/users/me'),
        body: {
          'deviceId': deviceId,
          'displayName': displayName,
          if (email.trim().isNotEmpty) 'email': email.trim(),
        },
      );
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.saveProfile(
        displayName: displayName,
        email: email,
      );
    }
  }

  @override
  Future<UserProfile> updatePreferences({
    required Set<String> preferredGenres,
    required double preferredRadiusKm,
  }) async {
    try {
      final payload = await _patchJson(
        _buildUri('/users/me/preferences'),
        body: {
          'preferredGenres': preferredGenres.toList(),
          'preferredRadiusKm': preferredRadiusKm.round(),
        },
      );
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.updatePreferences(
        preferredGenres: preferredGenres,
        preferredRadiusKm: preferredRadiusKm,
      );
    }
  }

  @override
  Future<List<Concert>> findFavorites() async {
    try {
      final payload = await _getJson(_buildUri('/users/me/favorites'));
      return (payload as List<dynamic>)
          .map((item) => Concert.fromJson(item as Map<String, dynamic>))
          .map((concert) => concert.copyWith(isFavorite: true))
          .toList();
    } catch (_) {
      return _fallbackRepository.findFavorites();
    }
  }

  @override
  Future<void> signOut() async {
    await _identityStore.clearDeviceId();
    await _fallbackRepository.signOut();
  }

  Uri _buildUri(String path) {
    final normalizedBase = _baseUri.path.endsWith('/')
        ? _baseUri
        : _baseUri.replace(path: '${_baseUri.path}/');

    return normalizedBase.resolve(path.replaceFirst(RegExp('^/'), ''));
  }

  Future<Map<String, String>> _headers({
    bool json = false,
    bool includeDeviceId = true,
  }) async {
    final headers = <String, String>{};
    if (includeDeviceId) {
      headers['x-livearound-device-id'] =
          await _identityStore.getOrCreateDeviceId();
    }
    if (json) headers['content-type'] = 'application/json';
    return headers;
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 4));
    return _decode(response);
  }

  Future<dynamic> _postJson(
    Uri uri, {
    Map<String, dynamic>? body,
    bool includeDeviceId = true,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: await _headers(
            json: body != null,
            includeDeviceId: includeDeviceId,
          ),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 4));
    return _decode(response);
  }

  Future<dynamic> _patchJson(Uri uri,
      {required Map<String, dynamic> body}) async {
    final response = await _client
        .patch(
          uri,
          headers: await _headers(json: true),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 4));
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiRequestException(response.statusCode);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<UserProfile> _saveAuthSession(Map<String, dynamic> payload) async {
    final deviceId = payload['deviceId'] as String? ?? '';
    if (deviceId.isNotEmpty) {
      await _identityStore.saveDeviceId(deviceId);
    }

    return UserProfile.fromJson(payload['profile'] as Map<String, dynamic>);
  }
}

class ApiRequestException implements Exception {
  const ApiRequestException(this.statusCode);

  final int statusCode;

  bool get isClientError => statusCode >= 400 && statusCode < 500;
}
