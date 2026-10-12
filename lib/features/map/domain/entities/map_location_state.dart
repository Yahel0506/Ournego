import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/entities/reference_location.dart';

/// What the map knows about the user's location at a given moment.
class MapLocationState {
  final LocationAccessStatus status;

  /// Latest GPS fix. Null whenever access is lost.
  final AppPosition? gpsPosition;

  final ManualZone? manualZone;

  /// True once the system already offered to turn the location service on
  /// during the current outage and the user declined. It stops the app from
  /// re-opening the native dialog every time it returns to the foreground.
  final bool serviceDialogOffered;

  const MapLocationState({
    required this.status,
    this.gpsPosition,
    this.manualZone,
    this.serviceDialogOffered = false,
  });

  /// GPS first, then the manual zone, then the default zone. Never null.
  ReferenceLocation get reference {
    final gps = gpsPosition;
    if (gps != null) {
      return ReferenceLocation(
        position: gps,
        source: ReferenceLocationSource.gps,
        label: 'Tu ubicación',
      );
    }
    final zone = manualZone;
    if (zone != null) {
      return ReferenceLocation(
        position: zone.position,
        source: ReferenceLocationSource.manualZone,
        label: zone.label,
      );
    }
    return ReferenceLocation.defaultZone;
  }

  MapLocationState copyWith({
    LocationAccessStatus? status,
    AppPosition? gpsPosition,
    bool clearGpsPosition = false,
    ManualZone? manualZone,
    bool clearManualZone = false,
    bool? serviceDialogOffered,
  }) {
    return MapLocationState(
      status: status ?? this.status,
      gpsPosition: clearGpsPosition ? null : (gpsPosition ?? this.gpsPosition),
      manualZone: clearManualZone ? null : (manualZone ?? this.manualZone),
      serviceDialogOffered: serviceDialogOffered ?? this.serviceDialogOffered,
    );
  }
}
