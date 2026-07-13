import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../domain/user_profile.dart';
import '../../theme/livearound_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.accountRepository,
    required this.initialProfile,
    required this.onProfileChanged,
    required this.onSignOut,
    super.key,
  });

  final AccountRepository accountRepository;
  final UserProfile initialProfile;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late Set<String> _selectedGenres;
  late double _radiusKm;
  var _isSaving = false;

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
    _displayNameController = TextEditingController(
      text: widget.initialProfile.displayName,
    );
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _selectedGenres = widget.initialProfile.preferredGenres;
    _radiusKm = widget.initialProfile.preferredRadiusKm;
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile.id != widget.initialProfile.id) {
      _displayNameController.text = widget.initialProfile.displayName;
      _emailController.text = widget.initialProfile.email;
      _selectedGenres = widget.initialProfile.preferredGenres;
      _radiusKm = widget.initialProfile.preferredRadiusKm;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.accountRepository.saveProfile(
        displayName: _displayNameController.text,
        email: _emailController.text,
      );
      final updated = await widget.accountRepository.updatePreferences(
        preferredGenres: _selectedGenres,
        preferredRadiusKm: _radiusKm,
      );

      if (!mounted) return;
      widget.onProfileChanged(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistre.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.initialProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ProfileSummary(profile: profile),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
                labelText: 'Nom',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.alternate_email_rounded),
                labelText: 'E-mail',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Genres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final genre in _genres)
                  FilterChip(
                    label: Text(genre),
                    selected: _selectedGenres.contains(genre),
                    onSelected: (selected) {
                      setState(() {
                        final next = Set<String>.from(_selectedGenres);
                        selected ? next.add(genre) : next.remove(genre);
                        _selectedGenres = next;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.radar_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_radiusKm.round()} km',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            Slider(
              min: 5,
              max: 120,
              divisions: 23,
              value: _radiusKm.clamp(5, 120).toDouble(),
              onChanged: (value) {
                setState(() {
                  _radiusKm = value;
                });
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : widget.onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se deconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: LiveAroundTheme.teal,
              foregroundColor: Colors.white,
              child: Text(_initial(profile.displayName)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.favoritesCount} favoris',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.person_rounded),
          ],
        ),
      ),
    );
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'L';
  return trimmed.characters.first.toUpperCase();
}
