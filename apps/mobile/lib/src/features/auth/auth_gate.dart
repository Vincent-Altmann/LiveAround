import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/concert_repository.dart';
import '../../data/user_location_service.dart';
import '../../domain/user_profile.dart';
import '../home/home_shell.dart';
import 'auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.repository,
    required this.accountRepository,
    required this.locationLoader,
    super.key,
  });

  final ConcertRepository repository;
  final AccountRepository accountRepository;
  final UserLocationLoader locationLoader;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<UserProfile?> _sessionFuture;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _sessionFuture = widget.accountRepository.restoreSession();
  }

  void _handleAuthenticated(UserProfile profile) {
    setState(() {
      _profile = profile;
    });
  }

  Future<void> _handleSignOut() async {
    await widget.accountRepository.signOut();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _sessionFuture = Future<UserProfile?>.value(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile != null) {
      return _home(profile);
    }

    return FutureBuilder<UserProfile?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final restoredProfile = snapshot.data;
        if (restoredProfile != null) {
          return _home(restoredProfile);
        }

        return AuthPage(
          accountRepository: widget.accountRepository,
          onAuthenticated: _handleAuthenticated,
        );
      },
    );
  }

  Widget _home(UserProfile profile) {
    return HomeShell(
      repository: widget.repository,
      accountRepository: widget.accountRepository,
      locationLoader: widget.locationLoader,
      initialProfile: profile,
      onSignOut: _handleSignOut,
    );
  }
}
