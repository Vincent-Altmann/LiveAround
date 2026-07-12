import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/concert.dart';
import '../domain/concert_filters.dart';
import 'concert_repository.dart';

class ApiConcertRepository implements ConcertRepository {
  ApiConcertRepository({
    required String baseUrl,
    required ConcertRepository fallbackRepository,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl),
        _fallbackRepository = fallbackRepository,
        _client = client ?? http.Client();

  static const _lyonLatitude = 45.764;
  static const _lyonLongitude = 4.8357;

  final Uri _baseUri;
  final ConcertRepository _fallbackRepository;
  final http.Client _client;

  @override
  Future<List<Concert>> findNearby(ConcertFilters filters) async {
    try {
      final uri = _buildUri('/concerts', {
        'latitude': _lyonLatitude.toString(),
        'longitude': _lyonLongitude.toString(),
        'radiusKm': filters.radiusKm.round().toString(),
        if (filters.query.trim().isNotEmpty) 'query': filters.query.trim(),
        if (filters.selectedGenres.isNotEmpty)
          'genres': filters.selectedGenres.join(','),
      });

      final payload = await _getJson(uri);
      final concerts = (payload as List<dynamic>)
          .map((item) => Concert.fromJson(item as Map<String, dynamic>))
          .where((concert) => !filters.onlyFavorites || concert.isFavorite)
          .toList();

      return concerts;
    } catch (_) {
      return _fallbackRepository.findNearby(filters);
    }
  }

  @override
  Future<Concert?> findById(String id) async {
    try {
      final payload = await _getJson(_buildUri('/concerts/$id'));
      return Concert.fromJson(payload as Map<String, dynamic>);
    } catch (_) {
      return _fallbackRepository.findById(id);
    }
  }

  @override
  Future<Concert> toggleFavorite(String id) async {
    try {
      await _postJson(_buildUri('/concerts/$id/favorite'));
      final concert = await findById(id);
      if (concert != null) return concert;
    } catch (_) {
      return _fallbackRepository.toggleFavorite(id);
    }

    return _fallbackRepository.toggleFavorite(id);
  }

  @override
  Future<void> reportIncorrectData({
    required String concertId,
    required String reason,
  }) async {
    try {
      await _postJson(
        _buildUri('/concerts/$concertId/report'),
        body: {'reason': reason},
      );
    } catch (_) {
      return _fallbackRepository.reportIncorrectData(
        concertId: concertId,
        reason: reason,
      );
    }
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = _baseUri.path.endsWith('/')
        ? _baseUri
        : _baseUri.replace(path: '${_baseUri.path}/');

    return normalizedBase.resolve(path.replaceFirst(RegExp('^/'), '')).replace(
          queryParameters: queryParameters,
        );
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 4));
    return _decode(response);
  }

  Future<dynamic> _postJson(Uri uri, {Map<String, dynamic>? body}) async {
    final response = await _client
        .post(
          uri,
          headers: {'content-type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
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
