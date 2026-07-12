import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/concert.dart';
import '../../theme/livearound_theme.dart';

class ConcertMap extends StatelessWidget {
  const ConcertMap({
    required this.concerts,
    required this.onConcertTap,
    this.height = 240,
    this.initialZoom = 12,
    super.key,
  });

  final List<Concert> concerts;
  final ValueChanged<Concert> onConcertTap;
  final double height;
  final double initialZoom;

  static const _defaultCenter = LatLng(45.764, 4.8357);

  @override
  Widget build(BuildContext context) {
    final validConcerts = concerts
        .where((concert) =>
            concert.venue.latitude != 0 && concert.venue.longitude != 0)
        .toList();
    final center = validConcerts.isEmpty
        ? _defaultCenter
        : LatLng(
            validConcerts.first.venue.latitude,
            validConcerts.first.venue.longitude,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: initialZoom,
            minZoom: 4,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.livearound.app',
            ),
            MarkerLayer(
              markers: [
                for (final concert in validConcerts)
                  Marker(
                    point: LatLng(
                      concert.venue.latitude,
                      concert.venue.longitude,
                    ),
                    width: 48,
                    height: 48,
                    child: _ConcertMarker(
                      concert: concert,
                      onTap: () => onConcertTap(concert),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
                TextSourceAttribution('CARTO'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SingleConcertMap extends StatelessWidget {
  const SingleConcertMap({required this.concert, super.key});

  final Concert concert;

  @override
  Widget build(BuildContext context) {
    return ConcertMap(
      concerts: [concert],
      initialZoom: 15,
      height: 180,
      onConcertTap: (_) {},
    );
  }
}

class _ConcertMarker extends StatelessWidget {
  const _ConcertMarker({required this.concert, required this.onTap});

  final Concert concert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${concert.artist} - ${concert.venue.name}',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LiveAroundTheme.coral,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
