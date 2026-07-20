import 'package:flutter/material.dart';

import 'config/livearound_config.dart';
import 'data/account_repository.dart';
import 'data/api_account_repository.dart';
import 'data/api_concert_repository.dart';
import 'data/concert_repository.dart';
import 'data/device_identity_store.dart';
import 'data/mock_account_repository.dart';
import 'data/mock_concert_repository.dart';
import 'data/user_location_service.dart';
import 'features/auth/auth_gate.dart';
import 'theme/livearound_theme.dart';

class LiveAroundApp extends StatelessWidget {
  factory LiveAroundApp({
    ConcertRepository? repository,
    AccountRepository? accountRepository,
    TokenProvider? tokenProvider,
    UserLocationLoader? locationLoader,
    Key? key,
  }) {
    const identityStore = DeviceIdentityStore();
    final fallbackConcertRepository = MockConcertRepository();

    // Mode demonstration explicite : tout fonctionne sur des donnees mock,
    // sans API. Active avec --dart-define LIVEAROUND_DEMO_MODE=true.
    if (LiveAroundConfig.demoMode) {
      return LiveAroundApp._(
        repository: repository ?? fallbackConcertRepository,
        accountRepository: accountRepository ??
            MockAccountRepository(
              concertRepository: fallbackConcertRepository,
            ),
        locationLoader:
            locationLoader ?? const UserLocationService().determineLocation,
        key: key,
      );
    }

    final resolvedTokenProvider = tokenProvider ?? identityStore.readToken;

    // Signal declenche par le repository quand la session est irrecuperable
    // (jeton et refresh expires) : AuthGate revient a l'ecran de connexion.
    final sessionExpired = ValueNotifier<int>(0);

    return LiveAroundApp._(
      repository: repository ??
          ApiConcertRepository(
            baseUrl: LiveAroundConfig.apiBaseUrl,
            fallbackRepository: fallbackConcertRepository,
            tokenProvider: resolvedTokenProvider,
          ),
      accountRepository: accountRepository ??
          ApiAccountRepository(
            baseUrl: LiveAroundConfig.apiBaseUrl,
            identityStore: identityStore,
            fallbackRepository: MockAccountRepository(
              concertRepository: fallbackConcertRepository,
            ),
            onSessionExpired: () => sessionExpired.value++,
          ),
      locationLoader:
          locationLoader ?? const UserLocationService().determineLocation,
      sessionExpired: sessionExpired,
      key: key,
    );
  }

  const LiveAroundApp._({
    required this.repository,
    required this.accountRepository,
    required this.locationLoader,
    this.sessionExpired,
    super.key,
  });

  final ConcertRepository repository;
  final AccountRepository accountRepository;
  final UserLocationLoader locationLoader;
  final Listenable? sessionExpired;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveAround',
      debugShowCheckedModeBanner: false,
      theme: LiveAroundTheme.light(),
      home: AuthGate(
        repository: repository,
        accountRepository: accountRepository,
        locationLoader: locationLoader,
        sessionExpired: sessionExpired,
      ),
    );
  }
}
