import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/concert_repository.dart';
import '../../data/user_location_service.dart';
import '../../domain/concert.dart';
import '../../domain/concert_filters.dart';

/// Etat de l'ecran Decouvrir : filtres, resultats pagines, localisation.
///
/// Sorti du widget pour survivre aux reconstructions (fin des hacks a base
/// de ValueKey dans HomeShell) et pour porter la pagination : la liste
/// s'etend au fil du defilement sans repartir de zero.
class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    required ConcertRepository repository,
    required UserLocationLoader locationLoader,
  })  : _repository = repository,
        _locationLoader = locationLoader;

  static const _pageSize = 50;

  final ConcertRepository _repository;
  final UserLocationLoader _locationLoader;

  ConcertFilters _filters = const ConcertFilters();
  List<Concert> _concerts = const [];
  var _page = 0;
  var _initialized = false;
  var _disposed = false;

  var isLoading = false;
  var isLoadingMore = false;
  var hasError = false;
  var hasMore = false;
  var isResolvingLocation = false;

  ConcertFilters get filters => _filters;
  List<Concert> get concerts => List.unmodifiable(_concerts);

  /// Premiere entree sur l'ecran : resolution de la position puis chargement.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await resolveLocation();
  }

  Future<void> refresh() async {
    _page = 0;
    isLoading = true;
    hasError = false;
    _notify();

    try {
      final results = await _repository.findNearby(_filters);
      _concerts = results;
      hasMore = results.length >= _pageSize;
    } catch (_) {
      _concerts = const [];
      hasMore = false;
      hasError = true;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Charge la page suivante et l'ajoute a la liste (defilement infini).
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    _notify();

    try {
      final next = await _repository.findNearby(_filters, page: _page + 1);
      _page += 1;
      final knownIds = _concerts.map((concert) => concert.id).toSet();
      _concerts = [
        ..._concerts,
        ...next.where((concert) => !knownIds.contains(concert.id)),
      ];
      hasMore = next.length >= _pageSize;
    } catch (_) {
      // Echec de pagination : on garde la liste actuelle, sans page suivante.
      hasMore = false;
    } finally {
      isLoadingMore = false;
      _notify();
    }
  }

  void updateFilters(ConcertFilters filters) {
    _filters = filters;
    unawaited(refresh());
  }

  /// Met a jour la requete texte sans recharger (le debounce de l'UI
  /// declenche ensuite [refresh]).
  void setQuery(String query) {
    _filters = _filters.copyWith(query: query);
  }

  /// Ajuste le rayon affiche sans recharger (rechargement en fin de geste).
  void previewRadius(double radiusKm) {
    _filters = _filters.copyWith(radiusKm: radiusKm);
    _notify();
  }

  /// Applique les preferences du profil (genres, rayon) sans hack de rebuild.
  void applyPreferences({Set<String>? genres, double? radiusKm}) {
    _filters = _filters.copyWith(
      selectedGenres: genres,
      radiusKm: radiusKm?.clamp(5, 120),
    );
    if (_initialized) unawaited(refresh());
  }

  Future<void> resolveLocation() async {
    isResolvingLocation = true;
    _notify();

    final location = await _locationLoader();
    if (_disposed) return;

    _filters = _filters.copyWith(
      latitude: location.latitude,
      longitude: location.longitude,
      locationLabel: location.label,
      usesFallbackLocation: location.isFallback,
    );
    isResolvingLocation = false;
    await refresh();
  }

  void setManualLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    updateFilters(
      _filters.copyWith(
        latitude: latitude,
        longitude: longitude,
        locationLabel: label,
        usesFallbackLocation: false,
      ),
    );
  }

  /// Bascule un favori en mettant la liste a jour en place (pas de rechargement).
  Future<void> toggleFavorite(String concertId) async {
    final updated = await _repository.toggleFavorite(concertId);
    if (_disposed) return;

    _concerts = [
      for (final concert in _concerts)
        concert.id == updated.id ? updated : concert,
    ];
    _notify();
  }

  /// Resynchronise l'etat favori au retour d'une fiche concert.
  Future<void> syncConcert(String concertId) async {
    final refreshed = await _repository.findById(concertId);
    if (_disposed || refreshed == null) return;

    _concerts = [
      for (final concert in _concerts)
        concert.id == refreshed.id ? refreshed : concert,
    ];
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
