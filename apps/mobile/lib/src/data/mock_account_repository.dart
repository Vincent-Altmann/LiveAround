import '../domain/concert.dart';
import '../domain/concert_filters.dart';
import '../domain/user_profile.dart';
import 'account_repository.dart';
import 'mock_concert_repository.dart';

class MockAccountRepository implements AccountRepository {
  MockAccountRepository({MockConcertRepository? concertRepository})
      : _concertRepository = concertRepository ?? MockConcertRepository();

  final MockConcertRepository _concertRepository;
  UserProfile _profile = UserProfile.demo;

  @override
  Future<UserProfile> loadProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final favorites = await findFavorites();
    _profile = _profile.copyWith(favoritesCount: favorites.length);
    return _profile;
  }

  @override
  Future<UserProfile> saveProfile({
    required String displayName,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _profile = _profile.copyWith(
      displayName: displayName.trim().isEmpty
          ? UserProfile.demo.displayName
          : displayName.trim(),
      email: email.trim().isEmpty ? UserProfile.demo.email : email.trim(),
    );
    return _profile;
  }

  @override
  Future<UserProfile> updatePreferences({
    required Set<String> preferredGenres,
    required double preferredRadiusKm,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _profile = _profile.copyWith(
      preferredGenres: preferredGenres,
      preferredRadiusKm: preferredRadiusKm,
    );
    return _profile;
  }

  @override
  Future<List<Concert>> findFavorites() async {
    final concerts = await _concertRepository.findNearby(
      const ConcertFilters(radiusKm: 200, onlyFavorites: true),
    );
    return concerts.where((concert) => concert.isFavorite).toList();
  }
}
