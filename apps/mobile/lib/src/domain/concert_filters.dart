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
  });

  final String query;
  final double radiusKm;
  final Set<String> selectedGenres;
  final bool onlyFavorites;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final bool usesFallbackLocation;

  ConcertFilters copyWith({
    String? query,
    double? radiusKm,
    Set<String>? selectedGenres,
    bool? onlyFavorites,
    double? latitude,
    double? longitude,
    String? locationLabel,
    bool? usesFallbackLocation,
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
    );
  }
}
