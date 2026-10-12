/// Snapshot of what the device currently allows regarding location.
enum LocationAccessStatus {
  /// Permission granted and the location service is on.
  granted,

  /// Permission denied but it can still be requested again.
  permissionDenied,

  /// Permission denied permanently; only the system settings can change it.
  permissionDeniedForever,

  /// Permission granted but GPS / location services are turned off.
  serviceDisabled,

  /// The status could not be determined.
  unavailable,
}
