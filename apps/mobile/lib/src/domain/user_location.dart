class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.isFallback = false,
  });

  static const lyonFallback = UserLocation(
    latitude: 45.764,
    longitude: 4.8357,
    label: 'Lyon, France',
    isFallback: true,
  );

  final double latitude;
  final double longitude;
  final String label;
  final bool isFallback;
}
