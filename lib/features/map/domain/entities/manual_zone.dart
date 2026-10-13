import 'package:ournego/core/location/app_position.dart';

/// A place the user picked by hand to stand in for the device location.
class ManualZone {
  final AppPosition position;
  final String label;

  const ManualZone({required this.position, required this.label});
}
