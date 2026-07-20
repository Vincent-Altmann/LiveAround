import 'package:flutter_test/flutter_test.dart';
import 'package:livearound_mobile/src/data/concert_repository.dart';
import 'package:livearound_mobile/src/domain/concert.dart';
import 'package:livearound_mobile/src/domain/concert_filters.dart';
import 'package:livearound_mobile/src/domain/user_location.dart';
import 'package:livearound_mobile/src/features/discovery/discovery_controller.dart';

Concert _concert(String id, {bool isFavorite = false}) {
  return Concert(
    id: id,
    artist: 'Artiste $id',
    title: 'Concert $id',
    genre: 'Rock',
    startsAt: DateTime(2026, 8, 1, 20),
    venue: const Venue(
      name: 'Salle',
      city: 'Lyon',
      address: '',
      latitude: 45.76,
      longitude: 4.83,
    ),
    distanceKm: 1,
    priceFrom: 20,
    ticketUrl: '',
    description: '',
    isFavorite: isFavorite,
  );
}

class _PagedFakeRepository implements ConcertRepository {
  _PagedFakeRepository(this.pages);

  final List<List<Concert>> pages;
  var findNearbyCalls = 0;

  @override
  Future<List<Concert>> findNearby(ConcertFilters filters, {int page = 0}) async {
    findNearbyCalls += 1;
    if (page >= pages.length) return const [];
    return pages[page];
  }

  @override
  Future<Concert?> findById(String id) async => _concert(id, isFavorite: true);

  @override
  Future<Concert> toggleFavorite(String id) async =>
      _concert(id, isFavorite: true);

  @override
  Future<void> reportIncorrectData({
    required String concertId,
    required String reason,
  }) async {}
}

void main() {
  final fullPage = List.generate(50, (i) => _concert('p0-$i'));

  DiscoveryController buildController(_PagedFakeRepository repository) {
    return DiscoveryController(
      repository: repository,
      locationLoader: () async => UserLocation.lyonFallback,
    );
  }

  test('charge la premiere page et detecte une page suivante', () async {
    final repository = _PagedFakeRepository([fullPage]);
    final controller = buildController(repository);

    await controller.initialize();

    expect(controller.concerts.length, 50);
    expect(controller.hasMore, isTrue);
    expect(controller.isLoading, isFalse);
  });

  test('loadMore ajoute la page suivante en dedoublonnant', () async {
    final secondPage = [
      _concert('p0-0'), // doublon volontaire
      ...List.generate(10, (i) => _concert('p1-$i')),
    ];
    final repository = _PagedFakeRepository([fullPage, secondPage]);
    final controller = buildController(repository);

    await controller.initialize();
    await controller.loadMore();

    expect(controller.concerts.length, 60); // 50 + 11 - 1 doublon
    expect(controller.hasMore, isFalse); // 11 < 50
  });

  test('loadMore est inactif quand il n y a pas de page suivante', () async {
    final repository = _PagedFakeRepository([
      List.generate(6, (i) => _concert('seul-$i')),
    ]);
    final controller = buildController(repository);

    await controller.initialize();
    final callsAfterInit = repository.findNearbyCalls;
    await controller.loadMore();

    expect(repository.findNearbyCalls, callsAfterInit);
    expect(controller.concerts.length, 6);
  });

  test('toggleFavorite met le concert a jour en place', () async {
    final repository = _PagedFakeRepository([
      List.generate(6, (i) => _concert('c-$i')),
    ]);
    final controller = buildController(repository);

    await controller.initialize();
    await controller.toggleFavorite('c-2');

    expect(
      controller.concerts.firstWhere((c) => c.id == 'c-2').isFavorite,
      isTrue,
    );
    expect(controller.concerts.length, 6);
  });

  test('applyPreferences met a jour les filtres', () async {
    final repository = _PagedFakeRepository([fullPage]);
    final controller = buildController(repository);
    await controller.initialize();

    controller.applyPreferences(genres: {'Jazz'}, radiusKm: 200);

    expect(controller.filters.selectedGenres, {'Jazz'});
    expect(controller.filters.radiusKm, 120); // borne a 120
  });
}
