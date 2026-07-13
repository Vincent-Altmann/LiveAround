import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/concert_repository.dart';
import '../../domain/concert.dart';
import '../../theme/livearound_theme.dart';
import '../map/concert_map.dart';

class ConcertDetailPage extends StatefulWidget {
  const ConcertDetailPage({
    required this.concertId,
    required this.repository,
    super.key,
  });

  final String concertId;
  final ConcertRepository repository;

  @override
  State<ConcertDetailPage> createState() => _ConcertDetailPageState();
}

class _ConcertDetailPageState extends State<ConcertDetailPage> {
  late Future<Concert?> _concertFuture;

  @override
  void initState() {
    super.initState();
    _concertFuture = widget.repository.findById(widget.concertId);
  }

  Future<void> _toggleFavorite(Concert concert) async {
    await widget.repository.toggleFavorite(concert.id);
    setState(() {
      _concertFuture = widget.repository.findById(widget.concertId);
    });
  }

  Future<void> _openTickets(Concert concert) async {
    final url = Uri.tryParse(concert.ticketUrl);
    if (url == null || !url.hasScheme) {
      _showMessage('Billetterie indisponible pour ce concert.');
      return;
    }

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showMessage('Impossible d\'ouvrir la billetterie.');
      }
    } catch (_) {
      _showMessage('Impossible d\'ouvrir la billetterie.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _report(Concert concert) async {
    await widget.repository.reportIncorrectData(
      concertId: concert.id,
      reason: 'Signalement utilisateur depuis le MVP mobile',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signalement enregistre.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Concert')),
      body: FutureBuilder<Concert?>(
        future: _concertFuture,
        builder: (context, snapshot) {
          final concert = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (concert == null) {
            return const Center(child: Text('Concert introuvable'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeroPanel(concert: concert),
              const SizedBox(height: 16),
              Text(
                concert.artist,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                concert.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(concert.description),
              const SizedBox(height: 20),
              SingleConcertMap(concert: concert),
              const SizedBox(height: 20),
              _InfoSection(concert: concert),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: concert.ticketUrl.isEmpty
                          ? null
                          : () => _openTickets(concert),
                      icon: const Icon(Icons.confirmation_number_outlined),
                      label: const Text('Billetterie'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: concert.isFavorite
                        ? 'Retirer des favoris'
                        : 'Ajouter aux favoris',
                    onPressed: () => _toggleFavorite(concert),
                    icon: Icon(
                      concert.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Signaler une erreur',
                    onPressed: () => _report(concert),
                    icon: const Icon(Icons.flag_outlined),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.concert});

  final Concert concert;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [LiveAroundTheme.ink, LiveAroundTheme.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 24,
            top: 24,
            child: Icon(
              Icons.music_note_rounded,
              size: 84,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            right: 18,
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          concert.startsAt.day.toString().padLeft(2, '0'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _month(concert.startsAt.month),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${concert.venue.name}\n${concert.venue.city}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _month(int month) {
    const labels = [
      'JAN',
      'FEV',
      'MAR',
      'AVR',
      'MAI',
      'JUN',
      'JUL',
      'AOU',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return labels[month - 1];
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.concert});

  final Concert concert;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.schedule_rounded,
              label:
                  '${concert.startsAt.hour.toString().padLeft(2, '0')}:${concert.startsAt.minute.toString().padLeft(2, '0')}',
            ),
            _InfoRow(
              icon: Icons.place_outlined,
              label: '${concert.venue.address}, ${concert.venue.city}',
            ),
            _InfoRow(
              icon: Icons.radar_rounded,
              label: '${concert.distanceKm.toStringAsFixed(1)} km',
            ),
            _InfoRow(
              icon: Icons.euro_rounded,
              label: concert.priceFrom > 0
                  ? 'A partir de ${concert.priceFrom.round()} EUR'
                  : 'Prix non communique',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: LiveAroundTheme.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
