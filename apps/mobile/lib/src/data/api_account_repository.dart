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
    this.onSessionExpired,
  })  : _baseUri = Uri.parse(baseUrl),
        _identityStore = identityStore,
        _fallbackRepository = fallbackRepository ?? MockAccountRepository(),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final DeviceIdentityStore _identityStore;
  final AccountRepository _fallbackRepository;
  final http.Client _client;

  /// Appele quand la session est irrecuperable (jeton et refresh expires) :
  /// l'application doit revenir a l'ecran de connexion.
  final void Function()? onSessionExpired;

  Future<bool>? _refreshInFlight;

  @override
  Future<UserProfile?> restoreSession() async {
    final token = await _identityStore.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final payload = await _getJson(_buildUri('/users/me'));
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } on ApiRequestException {
      // 401 apres tentative de refresh : session invalide, deja nettoyee.
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
    bool? favoriteRemindersOptIn,
  }) async {
    try {
      final payload = await _patchJson(
        _buildUri('/users/me/preferences'),
        body: {
          'preferredGenres': preferredGenres.toList(),
          'preferredRadiusKm': preferredRadiusKm.round(),
          if (notificationOptIn != null)
            'notificationOptIn': notificationOptIn,
          if (favoriteRemindersOptIn != null)
            'favoriteRemindersOptIn': favoriteRemindersOptIn,
        },
      );
      return UserProfile.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.updatePreferences(
        preferredGenres: preferredGenres,
        preferredRadiusKm: preferredRadiusKm,
        notificationOptIn: notificationOptIn,
        favoriteRemindersOptIn: favoriteRemindersOptIn,
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
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final payload = await _postJson(
        _buildUri('/auth/change-password'),
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      // L'API revoque toutes les sessions et en emet une nouvelle pour cet
      // appareil : on la memorise pour rester connecte.
      await _saveAuthSession(payload as Map<String, dynamic>);
    } on ApiRequestException {
      rethrow;
    } catch (_) {
      throw const ApiUnavailableException();
    }
  }

  @override
  Future<String?> requestPasswordReset({required String email}) async {
    try {
      final payload = await _postJson(
        _buildUri('/auth/forgot-password'),
        body: {'email': email.trim()},
        authenticated: false,
      );
      return (payload as Map<String, dynamic>)['devCode'] as String?;
    } on ApiRequestException {
      rethrow;
    } catch (_) {
      throw const ApiUnavailableException();
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _postJson(
        _buildUri('/auth/reset-password'),
        body: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
        authenticated: false,
      );
    } on ApiRequestException {
      rethrow;
    } catch (_) {
      throw const ApiUnavailableException();
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    try {
      await _sendJson(
        'DELETE',
        _buildUri('/users/me'),
        body: {'password': password},
      );
      await _identityStore.clearSession();
    } on ApiRequestException {
      rethrow;
    } catch (_) {
      throw const ApiUnavailableException();
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

  Future<dynamic> _getJson(Uri uri) {
    return _sendJson('GET', uri);
  }

  Future<dynamic> _postJson(
    Uri uri, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _sendJson('POST', uri, body: body, authenticated: authenticated);
  }

  Future<dynamic> _patchJson(Uri uri, {required Map<String, dynamic> body}) {
    return _sendJson('PATCH', uri, body: body);
  }

  /// Toutes les requetes passent ici : sur un 401 authentifie, une tentative
  /// de renouvellement (refresh token) est faite puis la requete rejouee.
  /// Si la session reste invalide, elle est purgee et l'application est
  /// prevenue via [onSessionExpired].
  Future<dynamic> _sendJson(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    var response = await _sendOnce(
      method,
      uri,
      body: body,
      authenticated: authenticated,
    );

    if (authenticated && response.statusCode == 401) {
      if (await _refreshSession()) {
        response = await _sendOnce(
          method,
          uri,
          body: body,
          authenticated: authenticated,
        );
      }

      if (response.statusCode == 401) {
        await _identityStore.clearSession();
        onSessionExpired?.call();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _sendOnce(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, uri);
    request.headers.addAll(
      await _headers(json: body != null, authenticated: authenticated),
    );
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 4));
    return http.Response.fromStream(streamed);
  }

  /// Renouvelle la session via le refresh token, en garantissant une seule
  /// tentative simultanee (les appels concurrents partagent le resultat).
  Future<bool> _refreshSession() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final attempt = _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = attempt;
    return attempt;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _identityStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _sendOnce(
        'POST',
        _buildUri('/auth/refresh'),
        body: {'refreshToken': refreshToken},
        authenticated: false,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      await _saveAuthSession(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      return true;
    } catch (_) {
      return false;
    }
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
      await _identityStore.saveSession(
        deviceId: deviceId,
        token: token,
        refreshToken: payload['refreshToken'] as String?,
      );
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
