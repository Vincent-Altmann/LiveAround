import 'package:flutter/material.dart';

import 'data/mock_concert_repository.dart';
import 'features/discovery/discovery_page.dart';
import 'theme/livearound_theme.dart';

class LiveAroundApp extends StatelessWidget {
  const LiveAroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveAround',
      debugShowCheckedModeBanner: false,
      theme: LiveAroundTheme.light(),
      home: DiscoveryPage(repository: MockConcertRepository()),
    );
  }
}
