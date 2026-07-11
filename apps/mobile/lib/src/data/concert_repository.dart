import '../domain/concert.dart';
import '../domain/concert_filters.dart';

abstract interface class ConcertRepository {
  Future<List<Concert>> findNearby(ConcertFilters filters);

  Future<Concert?> findById(String id);

  Future<Concert> toggleFavorite(String id);

  Future<void> reportIncorrectData({
    required String concertId,
    required String reason,
  });
}
