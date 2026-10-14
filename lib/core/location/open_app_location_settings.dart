import 'package:flutter/foundation.dart';

import 'package:geolocator/geolocator.dart';

/// What to tell the user when the platform has no settings page for the
/// location permission (the browser, for instance).
const webLocationPermissionHelp =
    'Activa la ubicación desde el candado junto a la dirección del navegador '
    'y recarga la página.';

/// Opens the system page where the user can allow location for this app.
///
/// Returns false when that is not possible (web, or the platform refuses), so
/// the caller can explain how to do it by hand instead of failing.
Future<bool> openAppLocationSettings() async {
  if (kIsWeb) return false;
  try {
    return await Geolocator.openAppSettings();
  } catch (_) {
    return false;
  }
}
