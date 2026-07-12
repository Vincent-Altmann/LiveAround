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
    required DeviceIdProvider deviceIdProvider,
    AccountRepository? fallbackRepository,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl),
        _deviceIdProvider = deviceIdProvider,
        _fallbackRepository = fallbackRepository ?? MockAccountRepository(),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final DeviceIdProvider _deviceIdProvider;
  final AccountRepository _fallbackRepository;
  final http.Client _client;

  @override
  Future<UserProfile> loadProfile() async {
    try {
      final deviceId = await _deviceIdProvider();
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
      final deviceId = await _deviceIdProvider();
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

  Uri _buildUri(String path) {
    final normalizedBase = _baseUri.path.endsWith('/')
        ? _baseUri
        : _baseUri.replace(path: '${_baseUri.path}/');

    return normalizedBase.resolve(path.replaceFirst(RegExp('^/'), ''));
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{
      'x-livearound-device-id': await _deviceIdProvider(),
    };
    if (json) headers['content-type'] = 'application/json';
    return headers;
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 4));
    return _decode(response);
  }

  Future<dynamic> _postJson(Uri uri, {Map<String, dynamic>? body}) async {
    final response = await _client
        .post(
          uri,
          headers: await _headers(json: body != null),
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
      throw StateError('API error ${response.statusCode}');
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
