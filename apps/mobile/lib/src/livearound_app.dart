import 'package:flutter/material.dart';

import 'config/livearound_config.dart';
import 'data/api_concert_repository.dart';
import 'data/concert_repository.dart';
import 'data/mock_concert_repository.dart';
import 'features/discovery/discovery_page.dart';
import 'theme/livearound_theme.dart';

class LiveAroundApp extends StatelessWidget {
  LiveAroundApp({ConcertRepository? repository, super.key})
      : repository = repository ??
            ApiConcertRepository(
              baseUrl: LiveAroundConfig.apiBaseUrl,
              fallbackRepository: MockConcertRepository(),
            );

  final ConcertRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveAround',
      debugShowCheckedModeBanner: false,
      theme: LiveAroundTheme.light(),
      home: DiscoveryPage(repository: repository),
    );
  }
}
