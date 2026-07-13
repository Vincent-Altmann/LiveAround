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
  String? _password;
  var _isAuthenticated = false;

  @override
  Future<UserProfile?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _isAuthenticated ? loadProfile() : null;
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final normalizedEmail = email.trim().toLowerCase();
    if (_password != null &&
        (_password != password || _profile.email != normalizedEmail)) {
      throw StateError('Identifiants invalides');
    }

    _isAuthenticated = true;
    _profile = _profile.copyWith(email: normalizedEmail);
    return _profile;
  }

  @override
  Future<UserProfile> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _password = password;
    _isAuthenticated = true;
    _profile = _profile.copyWith(
      displayName: displayName.trim().isEmpty
          ? UserProfile.demo.displayName
          : displayName.trim(),
      email: email.trim().toLowerCase(),
    );
    return _profile;
  }

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
    bool? notificationOptIn,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _profile = _profile.copyWith(
      preferredGenres: preferredGenres,
      preferredRadiusKm: preferredRadiusKm,
      notificationOptIn: notificationOptIn,
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

  @override
  Future<void> signOut() async {
    _isAuthenticated = false;
  }
}
