import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/concert_repository.dart';
import '../../domain/concert.dart';
import '../../domain/concert_filters.dart';
import '../../domain/french_city.dart';
import '../../domain/user_location.dart';
import '../../theme/livearound_theme.dart';
import '../concert/concert_detail_page.dart';
import '../map/concert_map.dart';
import 'discovery_controller.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({
    required this.controller,
    required this.repository,
    this.onOpenNotifications,
    super.key,
  });

  final DiscoveryController controller;
  final ConcertRepository repository;
  final VoidCallback? onOpenNotifications;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  Timer? _searchDebounce;

  static const List<String> _genres = [
    'Rock',
    'Pop',
    'Electro',
    'Jazz',
    'Rap',
    'Classique',
  ];

  DiscoveryController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Chaque frappe ne declenche pas d'appel : on attend une pause de 400 ms
  // pour preserver le quota Ticketmaster (5 req/s, 5000 req/jour).
  void _onQueryChanged(String value) {
    _controller.setQuery(value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) unawaited(_controller.refresh());
    });
  }

  Future<void> _chooseLocation() async {
    final choice = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CityPickerSheet(),
    );
    if (!mounted || choice == null) return;

    if (choice == _CityPickerSheet.gpsChoice) {
      await _controller.resolveLocation();
      return;
    }

    final city = choice as FrenchCity;
    _controller.setManualLocation(
      latitude: city.latitude,
      longitude: city.longitude,
      label: city.name,
    );
  }

  Future<void> _applyDatePreset(_DatePreset preset) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filters = _controller.filters;

    switch (preset) {
      case _DatePreset.all:
        _controller.updateFilters(
          filters.copyWith(from: null, to: null, dateLabel: _DatePreset.all.label),
        );
      case _DatePreset.today:
        _controller.updateFilters(
          filters.copyWith(
            from: now,
            to: today.add(const Duration(days: 1)),
            dateLabel: _DatePreset.today.label,
          ),
        );
      case _DatePreset.weekend:
        final range = _weekendRange(now);
        _controller.updateFilters(
          filters.copyWith(
            from: range.$1,
            to: range.$2,
            dateLabel: _DatePreset.weekend.label,
          ),
        );
      case _DatePreset.week:
        _controller.updateFilters(
          filters.copyWith(
            from: now,
            to: now.add(const Duration(days: 7)),
            dateLabel: _DatePreset.week.label,
          ),
        );
      case _DatePreset.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: today,
          lastDate: today.add(const Duration(days: 365)),
          helpText: 'Periode des concerts',
        );
        if (picked == null) return;
        _controller.updateFilters(
          filters.copyWith(
            from: picked.start,
            to: picked.end.add(const Duration(days: 1)),
            dateLabel:
                '${_shortDate(picked.start)} - ${_shortDate(picked.end)}',
          ),
        );
    }
  }

  // Week-end courant s'il est en cours, sinon le prochain.
  (DateTime, DateTime) _weekendRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final DateTime saturday;
    if (now.weekday == DateTime.saturday) {
      saturday = today;
    } else if (now.weekday == DateTime.sunday) {
      saturday = today.subtract(const Duration(days: 1));
    } else {
      saturday = today.add(Duration(days: DateTime.saturday - now.weekday));
    }

    final from = saturday.isBefore(now) ? now : saturday;
    final to = saturday.add(const Duration(days: 2));
    return (from, to);
  }

  Future<void> _openDetail(Concert concert) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConcertDetailPage(
          concertId: concert.id,
          repository: widget.repository,
        ),
      ),
    );
    // Resynchronise uniquement le concert consulte (favori bascule sur la
    // fiche, par exemple) au lieu de recharger toute la liste.
    unawaited(_controller.syncConcert(concert.id));
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final remaining =
        notification.metrics.maxScrollExtent - notification.metrics.pixels;
    if (remaining < 600) {
      unawaited(_controller.loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveAround'),
        actions: [
          IconButton(
            tooltip: 'Alertes',
            onPressed: widget.onOpenNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final filters = _controller.filters;
            final concerts = _controller.concerts;

            return NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      filters: filters,
                      isResolvingLocation: _controller.isResolvingLocation,
                      onQueryChanged: _onQueryChanged,
                      onRefreshLocation: () =>
                          unawaited(_controller.resolveLocation()),
                      onChooseLocation: _chooseLocation,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _GenreFilters(
                      genres: _genres,
                      selectedGenres: filters.selectedGenres,
                      onChanged: (genres) {
                        _controller.updateFilters(
                          filters.copyWith(selectedGenres: genres),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _DateFilters(
                      currentLabel: filters.dateLabel,
                      onSelected: _applyDatePreset,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _RadiusFilter(
                      radiusKm: filters.radiusKm,
                      onChanged: _controller.previewRadius,
                      onChangeEnd: (radius) {
                        _controller.updateFilters(
                          _controller.filters.copyWith(radiusKm: radius),
                        );
                      },
                    ),
                  ),
                  if (_controller.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_controller.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(
                        onRetry: () => unawaited(_controller.refresh()),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: ConcertMap(
                          concerts: concerts,
                          userLocation: UserLocation(
                            latitude: filters.latitude,
                            longitude: filters.longitude,
                            label: filters.locationLabel,
                            isFallback: filters.usesFallbackLocation,
                          ),
                          onConcertTap: _openDetail,
                        ),
                      ),
                    ),
                    if (concerts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(filters: filters),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: _ResultsSummary(
                          count: concerts.length,
                          hasMore: _controller.hasMore,
                          onlyFavorites: filters.onlyFavorites,
                          onFavoriteFilterChanged: (enabled) {
                            _controller.updateFilters(
                              filters.copyWith(onlyFavorites: enabled),
                            );
                          },
                        ),
                      ),
                      SliverList.separated(
                        itemCount: concerts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final concert = concerts[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: ConcertCard(
                              concert: concert,
                              onTap: () => _openDetail(concert),
                              onFavoriteTap: () => unawaited(
                                _controller.toggleFavorite(concert.id),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_controller.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

enum _DatePreset {
  all('Toutes les dates'),
  today('Aujourd\'hui'),
  weekend('Ce week-end'),
  week('7 jours'),
  custom('Choisir...');

  const _DatePreset(this.label);

  final String label;
}

class _DateFilters extends StatelessWidget {
  const _DateFilters({
    required this.currentLabel,
    required this.onSelected,
  });

  final String currentLabel;
  final ValueChanged<_DatePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final isCustom = _DatePreset.values
        .every((preset) => preset.label != currentLabel);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: _DatePreset.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = _DatePreset.values[index];
          final selected = preset == _DatePreset.custom
              ? isCustom
              : preset.label == currentLabel;
          return FilterChip(
            avatar: preset == _DatePreset.custom
                ? const Icon(Icons.calendar_month_rounded, size: 18)
                : null,
            label: Text(
              preset == _DatePreset.custom && isCustom
                  ? currentLabel
                  : preset.label,
            ),
            selected: selected,
            onSelected: (_) => onSelected(preset),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.filters,
    required this.isResolvingLocation,
    required this.onQueryChanged,
    required this.onRefreshLocation,
    required this.onChooseLocation,
  });

  final ConcertFilters filters;
  final bool isResolvingLocation;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onRefreshLocation;
  final VoidCallback onChooseLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Concerts proches de vous',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LiveAroundTheme.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            filters.usesFallbackLocation
                ? 'Position par defaut : ${filters.locationLabel}'
                : 'Position : ${filters.locationLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.62),
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: isResolvingLocation ? null : onRefreshLocation,
                icon: isResolvingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  isResolvingLocation ? 'Localisation...' : 'Ma position',
                ),
              ),
              OutlinedButton.icon(
                onPressed: isResolvingLocation ? null : onChooseLocation,
                icon: const Icon(Icons.location_city_rounded),
                label: const Text('Choisir une ville'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Artiste, salle ou ville',
            ),
            onChanged: onQueryChanged,
          ),
        ],
      ),
    );
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  /// Valeur sentinelle renvoyee quand l'utilisateur prefere le GPS.
  static const gpsChoice = 'gps';

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final cities = frenchCities
        .where((city) => city.name.toLowerCase().contains(normalizedQuery))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ou chercher des concerts ?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Rechercher une ville',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.my_location_rounded),
                      title: const Text('Utiliser ma position (GPS)'),
                      onTap: () => Navigator.of(context)
                          .pop(_CityPickerSheet.gpsChoice),
                    ),
                    const Divider(height: 1),
                    for (final city in cities)
                      ListTile(
                        leading: const Icon(Icons.location_city_rounded),
                        title: Text(city.name),
                        onTap: () => Navigator.of(context).pop(city),
                      ),
                    if (cities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune ville trouvee. Essayez une grande ville proche de chez vous.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GenreFilters extends StatelessWidget {
  const _GenreFilters({
    required this.genres,
    required this.selectedGenres,
    required this.onChanged,
  });

  final List<String> genres;
  final Set<String> selectedGenres;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final selected = selectedGenres.contains(genre);
          return FilterChip(
            label: Text(genre),
            selected: selected,
            onSelected: (value) {
              final next = Set<String>.from(selectedGenres);
              value ? next.add(genre) : next.remove(genre);
              onChanged(next);
            },
          );
        },
      ),
    );
  }
}

class _RadiusFilter extends StatelessWidget {
  const _RadiusFilter({
    required this.radiusKm,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double radiusKm;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, size: 20),
          const SizedBox(width: 8),
          Text('${radiusKm.round()} km'),
          Expanded(
            child: Slider(
              min: 5,
              max: 120,
              divisions: 23,
              value: radiusKm.clamp(5, 120).toDouble(),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({
    required this.count,
    required this.hasMore,
    required this.onlyFavorites,
    required this.onFavoriteFilterChanged,
  });

  final int count;
  final bool hasMore;
  final bool onlyFavorites;
  final ValueChanged<bool> onFavoriteFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasMore ? '$count concerts et plus' : '$count concerts trouves',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          FilterChip(
            avatar: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Favoris'),
            selected: onlyFavorites,
            onSelected: onFavoriteFilterChanged,
          ),
        ],
      ),
    );
  }
}

class ConcertCard extends StatelessWidget {
  const ConcertCard({
    required this.concert,
    required this.onTap,
    required this.onFavoriteTap,
    super.key,
  });

  final Concert concert;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConcertThumbnail(concert: concert),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concert.artist,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(concert.title),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaPill(
                          icon: Icons.music_note_rounded,
                          label: concert.genre,
                        ),
                        _MetaPill(
                          icon: Icons.place_outlined,
                          label: '${concert.distanceKm.toStringAsFixed(1)} km',
                        ),
                        _MetaPill(
                          icon: Icons.confirmation_number_outlined,
                          label: concert.priceFrom > 0
                              ? 'des ${concert.priceFrom.round()} EUR'
                              : 'Prix NC',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${concert.venue.name}, ${concert.venue.city}',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: concert.isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: onFavoriteTap,
                icon: Icon(
                  concert.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: concert.isFavorite
                      ? LiveAroundTheme.coral
                      : Colors.black.withValues(alpha: 0.54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vignette du concert : image de l'artiste (fournie par Ticketmaster) avec
/// la date en surimpression, ou bloc date seul quand il n'y a pas d'image.
class _ConcertThumbnail extends StatelessWidget {
  const _ConcertThumbnail({required this.concert});

  final Concert concert;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${concert.startsAt.day.toString().padLeft(2, '0')}/${concert.startsAt.month.toString().padLeft(2, '0')}';
    final timeLabel =
        '${concert.startsAt.hour.toString().padLeft(2, '0')}:${concert.startsAt.minute.toString().padLeft(2, '0')}';

    final dateBox = Container(
      width: 68,
      height: 88,
      decoration: BoxDecoration(
        color: LiveAroundTheme.teal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeLabel,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
          ),
        ],
      ),
    );

    final imageUrl = concert.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return dateBox;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 68,
        height: 88,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => dateBox,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: Colors.black.withValues(alpha: 0.55),
                child: Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les concerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifiez votre connexion puis reessayez.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filters});

  final ConcertFilters filters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'Aucun concert dans ce rayon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              filters.hasDateRange
                  ? 'Elargissez le rayon de ${filters.radiusKm.round()} km, changez de periode ou retirez un filtre.'
                  : 'Elargissez le rayon de ${filters.radiusKm.round()} km ou retirez un filtre.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
