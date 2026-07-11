class ConcertFilters {
  const ConcertFilters({
    this.query = '',
    this.radiusKm = 25,
    this.selectedGenres = const <String>{},
    this.onlyFavorites = false,
  });

  final String query;
  final double radiusKm;
  final Set<String> selectedGenres;
  final bool onlyFavorites;

  ConcertFilters copyWith({
    String? query,
    double? radiusKm,
    Set<String>? selectedGenres,
    bool? onlyFavorites,
  }) {
    return ConcertFilters(
      query: query ?? this.query,
      radiusKm: radiusKm ?? this.radiusKm,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
    );
  }
}
