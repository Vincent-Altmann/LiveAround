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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Demande un code de reinitialisation. Renvoie le code en environnement
  /// de developpement (l'envoi par email reste a brancher cote API).
  Future<String?> requestPasswordReset({required String email});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Suppression definitive du compte (RGPD), confirmee par mot de passe.
  Future<void> deleteAccount({required String password});

  Future<void> signOut();
}
