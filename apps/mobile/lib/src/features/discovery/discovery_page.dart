import 'package:flutter/material.dart';

import '../../data/concert_repository.dart';
import '../../domain/concert.dart';
import '../../domain/concert_filters.dart';
import '../../theme/livearound_theme.dart';
import '../concert/concert_detail_page.dart';
import '../map/concert_map.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({required this.repository, super.key});

  final ConcertRepository repository;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  ConcertFilters _filters = const ConcertFilters();
  late Future<List<Concert>> _concertsFuture;

  static const List<String> _genres = [
    'Rock',
    'Pop',
    'Electro',
    'Jazz',
    'Rap',
    'Classique',
  ];

  @override
  void initState() {
    super.initState();
    _concertsFuture = widget.repository.findNearby(_filters);
  }

  void _refresh() {
    setState(() {
      _concertsFuture = widget.repository.findNearby(_filters);
    });
  }

  void _updateFilters(ConcertFilters filters) {
    _filters = filters;
    _refresh();
  }

  Future<void> _toggleFavorite(Concert concert) async {
    await widget.repository.toggleFavorite(concert.id);
    _refresh();
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
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveAround'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Les alertes seront activees avec FCM.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Concert>>(
          future: _concertsFuture,
          builder: (context, snapshot) {
            final concerts = snapshot.data ?? const <Concert>[];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(filters: _filters, onChanged: _updateFilters),
                ),
                SliverToBoxAdapter(
                  child: _GenreFilters(
                    genres: _genres,
                    selectedGenres: _filters.selectedGenres,
                    onChanged: (genres) {
                      _updateFilters(
                        _filters.copyWith(selectedGenres: genres),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _RadiusFilter(
                    radiusKm: _filters.radiusKm,
                    onChanged: (radius) {
                      _updateFilters(_filters.copyWith(radiusKm: radius));
                    },
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (concerts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(filters: _filters),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ConcertMap(
                        concerts: concerts,
                        onConcertTap: _openDetail,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ResultsSummary(
                      count: concerts.length,
                      onlyFavorites: _filters.onlyFavorites,
                      onFavoriteFilterChanged: (enabled) {
                        _updateFilters(
                          _filters.copyWith(onlyFavorites: enabled),
                        );
                      },
                    ),
                  ),
                  SliverList.separated(
                    itemCount: concerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final concert = concerts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ConcertCard(
                          concert: concert,
                          onTap: () => _openDetail(concert),
                          onFavoriteTap: () => _toggleFavorite(concert),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.filters, required this.onChanged});

  final ConcertFilters filters;
  final ValueChanged<ConcertFilters> onChanged;

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
            'Position actuelle : Lyon, France',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.62),
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Artiste, salle ou ville',
            ),
            onChanged: (value) => onChanged(filters.copyWith(query: value)),
          ),
        ],
      ),
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
  const _RadiusFilter({required this.radiusKm, required this.onChanged});

  final double radiusKm;
  final ValueChanged<double> onChanged;

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
              max: 80,
              divisions: 15,
              value: radiusKm,
              onChanged: onChanged,
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
    required this.onlyFavorites,
    required this.onFavoriteFilterChanged,
  });

  final int count;
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
              '$count concerts trouves',
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
    final dateLabel =
        '${concert.startsAt.day.toString().padLeft(2, '0')}/${concert.startsAt.month.toString().padLeft(2, '0')}';
    final timeLabel =
        '${concert.startsAt.hour.toString().padLeft(2, '0')}:${concert.startsAt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
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
                          label: 'des ${concert.priceFrom.round()} EUR',
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
              'Elargissez le rayon de ${filters.radiusKm.round()} km ou retirez un filtre.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
