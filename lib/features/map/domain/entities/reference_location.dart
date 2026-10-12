import 'package:ournego/core/location/app_position.dart';

enum ReferenceLocationSource { gps, manualZone, defaultZone }

/// The point the map uses to center itself and measure distances. It always
/// exists: when there is no GPS fix it falls back to a manual or default zone.
class ReferenceLocation {
  final AppPosition position;
  final ReferenceLocationSource source;
  final String label;

  const ReferenceLocation({
    required this.position,
    required this.source,
    required this.label,
  });

  static const defaultZone = ReferenceLocation(
    position: AppPosition(latitude: 19.7000112, longitude: -103.4654738),
    source: ReferenceLocationSource.defaultZone,
    label: 'Ciudad Guzmán',
  );

  bool get isGps => source == ReferenceLocationSource.gps;
}
