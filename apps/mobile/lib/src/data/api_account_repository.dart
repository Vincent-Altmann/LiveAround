import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/app_notification.dart';
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
    final token = await _identityStore.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final payload = await _getJson(_buildUri('/users/me'));
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } on ApiRequestException catch (error) {
      if (error.isClientError) {
        // Jeton expire ou invalide : on force une nouvelle connexion.
        await _identityStore.clearSession();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    // Pas de repli mock ici : une connexion ne doit jamais "reussir" sur des
    // donnees de demonstration quand le serveur est injoignable.
    try {
      final payload = await _postJson(
        _buildUri('/auth/login'),
        body: {'email': email.trim(), 'password': password},
        authenticated: false,
      );
      return _saveAuthSession(payload as Map<String, dynamic>);
    } on ApiRequestException {
      rethrow;
    } catch (_) {
      throw const ApiUnavailableException();
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
        authenticated: false,
      );
      return _saveAuthSession(payload as Map<String, dynamic>);
    } on ApiRequestException {
      rethrow;
    } catch (_) {
      throw const ApiUnavailableException();
    }
  }

  @override
  Future<UserProfile> loadProfile() async {
    try {
      final payload = await _getJson(_buildUri('/users/me'));
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
      final payload = await _postJson(
        _buildUri('/users/me'),
        body: {
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
    bool? notificationOptIn,
  }) async {
    try {
      final payload = await _patchJson(
        _buildUri('/users/me/preferences'),
        body: {
          'preferredGenres': preferredGenres.toList(),
          'preferredRadiusKm': preferredRadiusKm.round(),
          if (notificationOptIn != null)
            'notificationOptIn': notificationOptIn,
        },
      );
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.updatePreferences(
        preferredGenres: preferredGenres,
        preferredRadiusKm: preferredRadiusKm,
        notificationOptIn: notificationOptIn,
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
  Future<List<AppNotification>> findNotifications() async {
    try {
      final payload = await _getJson(_buildUri('/users/me/notifications'));
      return (payload as List<dynamic>)
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallbackRepository.findNotifications();
    }
  }

  @override
  Future<void> markNotificationClicked(String notificationId) async {
    try {
      await _postJson(
        _buildUri('/users/me/notifications/$notificationId/click'),
      );
    } catch (_) {
      // Le clic sert a la mesure de pertinence : ne jamais bloquer l'ouverture.
    }
  }

  @override
  Future<void> signOut() async {
    await _identityStore.clearSession();
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
    bool authenticated = true,
  }) async {
    final headers = <String, String>{};
    if (authenticated) {
      final token = await _identityStore.readToken();
      if (token != null && token.isNotEmpty) {
        headers['authorization'] = 'Bearer $token';
      }
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
    bool authenticated = true,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: await _headers(
            json: body != null,
            authenticated: authenticated,
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
    final token = payload['accessToken'] as String? ?? '';
    if (deviceId.isNotEmpty && token.isNotEmpty) {
      await _identityStore.saveSession(deviceId: deviceId, token: token);
    }

    return UserProfile.fromJson(payload['profile'] as Map<String, dynamic>);
  }
}

class ApiRequestException implements Exception {
  const ApiRequestException(this.statusCode);

  final int statusCode;

  bool get isClientError => statusCode >= 400 && statusCode < 500;
}

/// Serveur injoignable (reseau coupe, API arretee, timeout).
class ApiUnavailableException implements Exception {
  const ApiUnavailableException();
}
