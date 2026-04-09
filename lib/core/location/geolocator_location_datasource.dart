import 'package:geolocator/geolocator.dart' as geolocator;

import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';

class GeolocatorLocationDatasource implements LocationDatasource {
  @override
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    final serviceEnabled =
        await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await geolocator.Geolocator.checkPermission();

    if (permission == geolocator.LocationPermission.denied &&
        requestPermissionIfNeeded) {
      permission = await geolocator.Geolocator.requestPermission();
    }

    if (permission == geolocator.LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return AppPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on geolocator.LocationServiceDisabledException {
      throw const LocationServiceDisabledException();
    } on Exception {
      throw const LocationUnavailableException();
    }
  }
}
