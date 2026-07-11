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
