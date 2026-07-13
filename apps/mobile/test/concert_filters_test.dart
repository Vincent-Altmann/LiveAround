import 'package:flutter_test/flutter_test.dart';
import 'package:livearound_mobile/src/data/mock_concert_repository.dart';
import 'package:livearound_mobile/src/domain/concert_filters.dart';

void main() {
  group('ConcertFilters.copyWith', () {
    test('conserve la plage de dates quand elle n est pas fournie', () {
      final filters = const ConcertFilters().copyWith(
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 7, 27),
      );

      final updated = filters.copyWith(radiusKm: 50);

      expect(updated.from, DateTime(2026, 7, 20));
      expect(updated.to, DateTime(2026, 7, 27));
      expect(updated.radiusKm, 50);
    });

    test('permet d effacer la plage de dates avec null', () {
      final filters = const ConcertFilters().copyWith(
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 7, 27),
      );

      final cleared = filters.copyWith(from: null, to: null);

      expect(cleared.from, isNull);
      expect(cleared.to, isNull);
      expect(cleared.hasDateRange, isFalse);
    });
  });

  group('MockConcertRepository.findNearby', () {
    test('filtre les concerts par plage de dates', () async {
      final repository = MockConcertRepository();

      final all = await repository.findNearby(const ConcertFilters());
      final july = await repository.findNearby(
        const ConcertFilters().copyWith(
          from: DateTime(2026, 7, 1),
          to: DateTime(2026, 7, 31),
        ),
      );

      expect(all.length, greaterThan(july.length));
      expect(
        july.every(
          (concert) =>
              concert.startsAt.isAfter(DateTime(2026, 6, 30)) &&
              concert.startsAt.isBefore(DateTime(2026, 8, 1)),
        ),
        isTrue,
      );
    });

    test('filtre par genre et rayon combines', () async {
      final repository = MockConcertRepository();

      final results = await repository.findNearby(
        const ConcertFilters(
          selectedGenres: {'Jazz'},
          radiusKm: 10,
        ),
      );

      expect(results, isNotEmpty);
      expect(results.every((concert) => concert.genre == 'Jazz'), isTrue);
      expect(results.every((concert) => concert.distanceKm <= 10), isTrue);
    });
  });
}
