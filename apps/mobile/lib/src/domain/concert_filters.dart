class ConcertFilters {
  const ConcertFilters({
    this.query = '',
    this.radiusKm = 25,
    this.selectedGenres = const <String>{},
    this.onlyFavorites = false,
    this.latitude = 45.764,
    this.longitude = 4.8357,
    this.locationLabel = 'Lyon, France',
    this.usesFallbackLocation = true,
    this.from,
    this.to,
    this.dateLabel = 'Toutes les dates',
  });

  final String query;
  final double radiusKm;
  final Set<String> selectedGenres;
  final bool onlyFavorites;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final bool usesFallbackLocation;
  final DateTime? from;
  final DateTime? to;
  final String dateLabel;

  bool get hasDateRange => from != null || to != null;

  // Sentinelle pour permettre a copyWith de remettre from/to a null
  // (le classique `from ?? this.from` ne sait pas effacer une valeur).
  static const Object _unset = Object();

  ConcertFilters copyWith({
    String? query,
    double? radiusKm,
    Set<String>? selectedGenres,
    bool? onlyFavorites,
    double? latitude,
    double? longitude,
    String? locationLabel,
    bool? usesFallbackLocation,
    Object? from = _unset,
    Object? to = _unset,
    String? dateLabel,
  }) {
    return ConcertFilters(
      query: query ?? this.query,
      radiusKm: radiusKm ?? this.radiusKm,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      usesFallbackLocation: usesFallbackLocation ?? this.usesFallbackLocation,
      from: identical(from, _unset) ? this.from : from as DateTime?,
      to: identical(to, _unset) ? this.to : to as DateTime?,
      dateLabel: dateLabel ?? this.dateLabel,
    );
  }
}
