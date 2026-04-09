class AppPosition {
  final double latitude;
  final double longitude;
  final String? address;

  const AppPosition({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}
