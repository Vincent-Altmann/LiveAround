import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api_account_repository.dart';
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
  late bool _notificationOptIn;
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
    _notificationOptIn = widget.initialProfile.notificationOptIn;
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile.id != widget.initialProfile.id) {
      _displayNameController.text = widget.initialProfile.displayName;
      _emailController.text = widget.initialProfile.email;
      _selectedGenres = widget.initialProfile.preferredGenres;
      _radiusKm = widget.initialProfile.preferredRadiusKm;
      _notificationOptIn = widget.initialProfile.notificationOptIn;
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
        notificationOptIn: _notificationOptIn,
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
            const SizedBox(height: 12),
            SwitchListTile(
              value: _notificationOptIn,
              onChanged: (value) {
                setState(() {
                  _notificationOptIn = value;
                });
              },
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Alertes concerts'),
              subtitle: const Text(
                'Etre prevenu des nouveaux concerts correspondant a vos genres et votre rayon.',
              ),
              contentPadding: EdgeInsets.zero,
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
            const SizedBox(height: 28),
            Text(
              'Securite',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _changePassword,
              icon: const Icon(Icons.password_rounded),
              label: const Text('Changer le mot de passe'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _deleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Supprimer mon compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        accountRepository: widget.accountRepository,
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifie.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAccountDialog(
        accountRepository: widget.accountRepository,
      ),
    );

    if (deleted == true && mounted) {
      widget.onSignOut();
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.accountRepository});

  final AccountRepository accountRepository;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  var _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newController.text.length < 8) {
      setState(() => _error = 'Nouveau mot de passe : minimum 8 caracteres.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await widget.accountRepository.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiRequestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.statusCode == 401
            ? 'Mot de passe actuel invalide.'
            : 'Modification impossible, reessayez plus tard.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Modification impossible, reessayez plus tard.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline_rounded),
              labelText: 'Mot de passe actuel',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_reset_rounded),
              labelText: 'Nouveau mot de passe',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isBusy ? null : _submit,
          child: Text(_isBusy ? 'Patientez...' : 'Modifier'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.accountRepository});

  final AccountRepository accountRepository;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  var _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await widget.accountRepository.deleteAccount(
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiRequestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.statusCode == 401
            ? 'Mot de passe invalide.'
            : 'Suppression impossible, reessayez plus tard.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Suppression impossible, reessayez plus tard.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer mon compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cette action est definitive : profil, preferences, favoris et alertes seront supprimes.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline_rounded),
              labelText: 'Mot de passe',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isBusy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(_isBusy ? 'Patientez...' : 'Supprimer definitivement'),
        ),
      ],
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
