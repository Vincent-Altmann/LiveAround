import '../domain/app_notification.dart';
import '../domain/concert.dart';
import '../domain/user_profile.dart';

abstract interface class AccountRepository {
  Future<UserProfile?> restoreSession();

  Future<UserProfile> login({
    required String email,
    required String password,
  });

  Future<UserProfile> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<UserProfile> loadProfile();

  Future<UserProfile> saveProfile({
    required String displayName,
    required String email,
  });

  Future<UserProfile> updatePreferences({
    required Set<String> preferredGenres,
    required double preferredRadiusKm,
    bool? notificationOptIn,
  });

  Future<List<Concert>> findFavorites();

  Future<List<AppNotification>> findNotifications();

  Future<void> markNotificationClicked(String notificationId);

  Future<void> signOut();
}
