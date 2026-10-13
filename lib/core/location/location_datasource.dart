import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';

abstract class LocationDatasource {
  /// Reads permission and service state without prompting the user.
  Future<LocationAccessStatus> checkAccessStatus();

  /// Shows the system permission dialog when it can still be shown and
  /// returns the resulting status.
  Future<LocationAccessStatus> requestPermission();

  /// Emits `true` when the device location service turns on and `false` when
  /// it turns off.
  Stream<bool> serviceStatusStream();

  /// When [resolveServiceIfDisabled] is true and the service is off, the
  /// native "turn on location" dialog is shown (Android) instead of failing
  /// right away.
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
    bool resolveServiceIfDisabled = false,
  });
}
