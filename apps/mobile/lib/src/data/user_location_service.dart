import 'package:geolocator/geolocator.dart';

import '../domain/user_location.dart';

typedef UserLocationLoader = Future<UserLocation> Function();

class UserLocationService {
  const UserLocationService();

  Future<UserLocation> determineLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return UserLocation.lyonFallback;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return UserLocation.lyonFallback;
    }

    // getCurrentPosition peut lever (timeout, service coupe en cours de
    // route) : sans ce garde-fou, l'ecran restait bloque en chargement.
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return UserLocation.lyonFallback;
    }

    if (!_isMetropolitanFrance(position.latitude, position.longitude)) {
      return UserLocation.lyonFallback;
    }

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      label: 'Votre position',
    );
  }

  bool _isMetropolitanFrance(double latitude, double longitude) {
    return latitude >= 41.0 &&
        latitude <= 51.5 &&
        longitude >= -5.5 &&
        longitude <= 9.8;
  }
}
