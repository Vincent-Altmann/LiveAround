import '../domain/concert.dart';
import '../domain/concert_filters.dart';
import 'concert_repository.dart';

class MockConcertRepository implements ConcertRepository {
  MockConcertRepository()
      : _concerts = _seedConcerts
            .map((concert) => MapEntry(concert.id, concert))
            .toMap();

  final Map<String, Concert> _concerts;

  @override
  Future<List<Concert>> findNearby(ConcertFilters filters) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final normalizedQuery = filters.query.trim().toLowerCase();
    final results = _concerts.values.where((concert) {
      final matchesRadius = concert.distanceKm <= filters.radiusKm;
      final matchesGenre = filters.selectedGenres.isEmpty ||
          filters.selectedGenres.contains(concert.genre);
      final matchesFavorite = !filters.onlyFavorites || concert.isFavorite;
      final matchesQuery = normalizedQuery.isEmpty ||
          concert.artist.toLowerCase().contains(normalizedQuery) ||
          concert.title.toLowerCase().contains(normalizedQuery) ||
          concert.venue.city.toLowerCase().contains(normalizedQuery);

      return matchesRadius && matchesGenre && matchesFavorite && matchesQuery;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }

  @override
  Future<Concert?> findById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _concerts[id];
  }

  @override
  Future<Concert> toggleFavorite(String id) async {
    final concert = _concerts[id];
    if (concert == null) {
      throw StateError('Concert introuvable');
    }

    final updated = concert.copyWith(isFavorite: !concert.isFavorite);
    _concerts[id] = updated;
    return updated;
  }

  @override
  Future<void> reportIncorrectData({
    required String concertId,
    required String reason,
  }) async {
    if (!_concerts.containsKey(concertId)) {
      throw StateError('Concert introuvable');
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

extension _EntriesToMap<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() => Map<K, V>.fromEntries(this);
}

final List<Concert> _seedConcerts = [
  Concert(
    id: 'la-001',
    artist: 'The Velvet Echoes',
    title: 'Tournee d ete',
    genre: 'Rock',
    startsAt: DateTime(2026, 7, 24, 20, 30),
    venue: const Venue(
      name: 'Le Transbordeur',
      city: 'Villeurbanne',
      address: '3 boulevard Stalingrad',
      latitude: 45.7832,
      longitude: 4.8605,
    ),
    distanceKm: 4.8,
    priceFrom: 32,
    ticketUrl: 'https://tickets.example/livearound/la-001',
    description:
        'Un concert rock nerveux dans une salle lyonnaise emblematique.',
  ),
  Concert(
    id: 'la-002',
    artist: 'Nora Blue',
    title: 'Fragments acoustiques',
    genre: 'Pop',
    startsAt: DateTime(2026, 7, 27, 19, 45),
    venue: const Venue(
      name: 'Radiant-Bellevue',
      city: 'Caluire-et-Cuire',
      address: '1 rue Jean Moulin',
      latitude: 45.7958,
      longitude: 4.8446,
    ),
    distanceKm: 6.1,
    priceFrom: 28,
    ticketUrl: 'https://tickets.example/livearound/la-002',
    description: 'Une soiree pop lumineuse avec une scenographie intimiste.',
  ),
  Concert(
    id: 'la-003',
    artist: 'Collectif Minuit',
    title: 'Warehouse live session',
    genre: 'Electro',
    startsAt: DateTime(2026, 8, 2, 23),
    venue: const Venue(
      name: 'Ninkasi Gerland',
      city: 'Lyon',
      address: '267 rue Marcel Merieux',
      latitude: 45.7272,
      longitude: 4.8307,
    ),
    distanceKm: 7.4,
    priceFrom: 24,
    ticketUrl: 'https://tickets.example/livearound/la-003',
    description:
        'Set electro nocturne, pense pour les amateurs de decouverte locale.',
  ),
  Concert(
    id: 'la-004',
    artist: 'Maya Quartet',
    title: 'Jazz sur la Saone',
    genre: 'Jazz',
    startsAt: DateTime(2026, 8, 9, 21),
    venue: const Venue(
      name: 'Hot Club de Lyon',
      city: 'Lyon',
      address: '26 rue Lanterne',
      latitude: 45.7669,
      longitude: 4.8277,
    ),
    distanceKm: 2.2,
    priceFrom: 18,
    ticketUrl: 'https://tickets.example/livearound/la-004',
    description:
        'Quartet jazz moderne, parfait pour une sortie de derniere minute.',
  ),
  Concert(
    id: 'la-005',
    artist: 'Kobalt',
    title: 'Nord Sud',
    genre: 'Rap',
    startsAt: DateTime(2026, 8, 14, 20),
    venue: const Venue(
      name: 'Halle Tony Garnier',
      city: 'Lyon',
      address: '20 place Docteurs Merieux',
      latitude: 45.7302,
      longitude: 4.8239,
    ),
    distanceKm: 8.2,
    priceFrom: 39,
    ticketUrl: 'https://tickets.example/livearound/la-005',
    description:
        'Plateau rap francophone avec premiere partie locale selectionnee.',
  ),
  Concert(
    id: 'la-006',
    artist: 'Solstice Strings',
    title: 'Classiques au parc',
    genre: 'Classique',
    startsAt: DateTime(2026, 8, 21, 18, 30),
    venue: const Venue(
      name: 'Auditorium de Lyon',
      city: 'Lyon',
      address: '149 rue Garibaldi',
      latitude: 45.7607,
      longitude: 4.8525,
    ),
    distanceKm: 3.7,
    priceFrom: 21,
    ticketUrl: 'https://tickets.example/livearound/la-006',
    description:
        'Programme accessible autour de cordes et pieces orchestrales.',
  ),
];
