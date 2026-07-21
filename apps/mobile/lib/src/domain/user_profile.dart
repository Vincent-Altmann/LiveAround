class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.preferredGenres,
    required this.preferredRadiusKm,
    required this.favoritesCount,
    this.notificationOptIn = false,
    this.favoriteRemindersOptIn = false,
  });

  final String id;
  final String email;
  final String displayName;
  final Set<String> preferredGenres;
  final double preferredRadiusKm;
  final int favoritesCount;
  final bool notificationOptIn;
  final bool favoriteRemindersOptIn;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Utilisateur LiveAround',
      preferredGenres:
          ((json['preferredGenres'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .toSet(),
      preferredRadiusKm: (json['preferredRadiusKm'] as num?)?.toDouble() ?? 25,
      favoritesCount: (json['favoritesCount'] as num?)?.toInt() ?? 0,
      notificationOptIn: json['notificationOptIn'] as bool? ?? false,
      favoriteRemindersOptIn:
          json['favoriteRemindersOptIn'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    Set<String>? preferredGenres,
    double? preferredRadiusKm,
    int? favoritesCount,
    bool? notificationOptIn,
    bool? favoriteRemindersOptIn,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      preferredRadiusKm: preferredRadiusKm ?? this.preferredRadiusKm,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      notificationOptIn: notificationOptIn ?? this.notificationOptIn,
      favoriteRemindersOptIn:
          favoriteRemindersOptIn ?? this.favoriteRemindersOptIn,
    );
  }

  static const demo = UserProfile(
    id: 'livearound-demo-device',
    email: 'demo@users.livearound.local',
    displayName: 'Utilisateur LiveAround',
    preferredGenres: <String>{},
    preferredRadiusKm: 25,
    favoritesCount: 0,
  );
}
