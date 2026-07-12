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
import 'features/home/home_shell.dart';
import 'theme/livearound_theme.dart';

class LiveAroundApp extends StatelessWidget {
  factory LiveAroundApp({
    ConcertRepository? repository,
    AccountRepository? accountRepository,
    DeviceIdProvider? deviceIdProvider,
    UserLocationLoader? locationLoader,
    Key? key,
  }) {
    final resolvedDeviceIdProvider =
        deviceIdProvider ?? const DeviceIdentityStore().getOrCreateDeviceId;
    final fallbackConcertRepository = MockConcertRepository();

    return LiveAroundApp._(
      repository: repository ??
          ApiConcertRepository(
            baseUrl: LiveAroundConfig.apiBaseUrl,
            fallbackRepository: fallbackConcertRepository,
            deviceIdProvider: resolvedDeviceIdProvider,
          ),
      accountRepository: accountRepository ??
          ApiAccountRepository(
            baseUrl: LiveAroundConfig.apiBaseUrl,
            deviceIdProvider: resolvedDeviceIdProvider,
            fallbackRepository: MockAccountRepository(
              concertRepository: fallbackConcertRepository,
            ),
          ),
      locationLoader:
          locationLoader ?? const UserLocationService().determineLocation,
      key: key,
    );
  }

  const LiveAroundApp._({
    required this.repository,
    required this.accountRepository,
    required this.locationLoader,
    super.key,
  });

  final ConcertRepository repository;
  final AccountRepository accountRepository;
  final UserLocationLoader locationLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveAround',
      debugShowCheckedModeBanner: false,
      theme: LiveAroundTheme.light(),
      home: HomeShell(
        repository: repository,
        accountRepository: accountRepository,
        locationLoader: locationLoader,
      ),
    );
  }
}
