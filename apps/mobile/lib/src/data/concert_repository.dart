import '../domain/concert.dart';
import '../domain/concert_filters.dart';

abstract interface class ConcertRepository {
  /// Recherche paginee (pages de 50, indexees a partir de 0).
  Future<List<Concert>> findNearby(ConcertFilters filters, {int page = 0});

  Future<Concert?> findById(String id);

  Future<Concert> toggleFavorite(String id);

  Future<void> reportIncorrectData({
    required String concertId,
    required String reason,
  });
}
