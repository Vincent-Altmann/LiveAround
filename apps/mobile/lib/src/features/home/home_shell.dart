import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/concert_repository.dart';
import '../../data/user_location_service.dart';
import '../../domain/user_profile.dart';
import '../discovery/discovery_page.dart';
import '../favorites/favorites_page.dart';
import '../profile/profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.repository,
    required this.accountRepository,
    required this.locationLoader,
    super.key,
  });

  final ConcertRepository repository;
  final AccountRepository accountRepository;
  final UserLocationLoader locationLoader;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _selectedIndex = 0;
  UserProfile? _profile;
  var _discoveryRevision = 0;
  var _favoritesRevision = 0;
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.accountRepository.loadProfile();
    _profileFuture.then((profile) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _discoveryRevision++;
      });
    });
  }

  void _handleProfileChanged(UserProfile profile) {
    setState(() {
      _profile = profile;
      _discoveryRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DiscoveryPage(
            key: ValueKey(
              'discovery-${profile?.preferredRadiusKm}-${profile?.preferredGenres.join(',')}-$_discoveryRevision',
            ),
            repository: widget.repository,
            locationLoader: widget.locationLoader,
            initialPreferredGenres: profile?.preferredGenres,
            initialRadiusKm: profile?.preferredRadiusKm,
          ),
          FavoritesPage(
            key: ValueKey('favorites-$_favoritesRevision'),
            accountRepository: widget.accountRepository,
            concertRepository: widget.repository,
          ),
          FutureBuilder<UserProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              return ProfilePage(
                accountRepository: widget.accountRepository,
                initialProfile: _profile ?? snapshot.data ?? UserProfile.demo,
                onProfileChanged: _handleProfileChanged,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) _favoritesRevision++;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Decouvrir',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
