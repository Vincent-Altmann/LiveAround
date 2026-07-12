class Venue {
  const Venue({
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name'] as String? ?? 'Salle a confirmer',
      city: json['city'] as String? ?? 'Ville a confirmer',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Concert {
  const Concert({
    required this.id,
    required this.artist,
    required this.title,
    required this.genre,
    required this.startsAt,
    required this.venue,
    required this.distanceKm,
    required this.priceFrom,
    required this.ticketUrl,
    required this.description,
    this.isFavorite = false,
  });

  final String id;
  final String artist;
  final String title;
  final String genre;
  final DateTime startsAt;
  final Venue venue;
  final double distanceKm;
  final double priceFrom;
  final String ticketUrl;
  final String description;
  final bool isFavorite;

  factory Concert.fromJson(Map<String, dynamic> json) {
    return Concert(
      id: json['id'] as String,
      artist: json['artist'] as String? ?? 'Artiste',
      title: json['title'] as String? ?? 'Concert',
      genre: json['genre'] as String? ?? 'Musique',
      startsAt: DateTime.parse(json['startsAt'] as String),
      venue: Venue.fromJson(json['venue'] as Map<String, dynamic>),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      priceFrom: (json['priceFrom'] as num?)?.toDouble() ?? 0,
      ticketUrl: json['ticketUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Concert copyWith({bool? isFavorite}) {
    return Concert(
      id: id,
      artist: artist,
      title: title,
      genre: genre,
      startsAt: startsAt,
      venue: venue,
      distanceKm: distanceKm,
      priceFrom: priceFrom,
      ticketUrl: ticketUrl,
      description: description,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
