/// Alerte personnalisee generee par l'API (nouveaux concerts correspondant
/// aux preferences). Consultee in-app en attendant le push FCM.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.concertId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.clickedAt,
    this.kind = 'new_concert',
  });

  final String id;
  final String concertId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? clickedAt;

  /// 'new_concert' (alerte decouverte) ou 'favorite_reminder' (rappel).
  final String kind;

  bool get isRead => clickedAt != null;

  bool get isFavoriteReminder => kind == 'favorite_reminder';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      concertId: json['concertId'] as String? ?? '',
      title: json['title'] as String? ?? 'Nouveau concert',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      clickedAt: json['clickedAt'] == null
          ? null
          : DateTime.parse(json['clickedAt'] as String),
      kind: json['kind'] as String? ?? 'new_concert',
    );
  }
}
