import '../domain/concert.dart';
import '../domain/user_profile.dart';

abstract interface class AccountRepository {
  Future<UserProfile> loadProfile();

  Future<UserProfile> saveProfile({
    required String displayName,
    required String email,
  });

  Future<UserProfile> updatePreferences({
    required Set<String> preferredGenres,
    required double preferredRadiusKm,
  });

  Future<List<Concert>> findFavorites();
}
