import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/concert_repository.dart';
import '../../domain/concert.dart';
import '../concert/concert_detail_page.dart';
import '../discovery/discovery_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    required this.accountRepository,
    required this.concertRepository,
    super.key,
  });

  final AccountRepository accountRepository;
  final ConcertRepository concertRepository;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Concert>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _favoritesFuture = widget.accountRepository.findFavorites();
  }

  Future<void> _toggleFavorite(Concert concert) async {
    await widget.concertRepository.toggleFavorite(concert.id);
    setState(_refresh);
  }

  Future<void> _openDetail(Concert concert) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConcertDetailPage(
          concertId: concert.id,
          repository: widget.concertRepository,
        ),
      ),
    );
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: SafeArea(
        child: FutureBuilder<List<Concert>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger vos favoris',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(_refresh),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final concerts = snapshot.data ?? const <Concert>[];
            if (concerts.isEmpty) {
              return const _EmptyFavorites();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(_refresh);
                await _favoritesFuture;
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: concerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final concert = concerts[index];
                  return ConcertCard(
                    concert: concert,
                    onTap: () => _openDetail(concert),
                    onFavoriteTap: () => _toggleFavorite(concert),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, size: 48),
            SizedBox(height: 12),
            Text(
              'Aucun favori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
