import 'package:flutter/material.dart';

import 'config/livearound_config.dart';
import 'data/api_concert_repository.dart';
import 'data/concert_repository.dart';
import 'data/mock_concert_repository.dart';
import 'data/user_location_service.dart';
import 'features/discovery/discovery_page.dart';
import 'theme/livearound_theme.dart';

class LiveAroundApp extends StatelessWidget {
  LiveAroundApp({
    ConcertRepository? repository,
    UserLocationLoader? locationLoader,
    super.key,
  })  : locationLoader =
            locationLoader ?? const UserLocationService().determineLocation,
        repository = repository ??
            ApiConcertRepository(
              baseUrl: LiveAroundConfig.apiBaseUrl,
              fallbackRepository: MockConcertRepository(),
            );

  final ConcertRepository repository;
  final UserLocationLoader locationLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveAround',
      debugShowCheckedModeBanner: false,
      theme: LiveAroundTheme.light(),
      home: DiscoveryPage(
        repository: repository,
        locationLoader: locationLoader,
      ),
    );
  }
}
