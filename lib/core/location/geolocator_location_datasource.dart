import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:geolocator/geolocator.dart' as geolocator;

import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';

class GeolocatorLocationDatasource implements LocationDatasource {
  static const _positionTimeout = Duration(seconds: 12);

  // Leaves room for the user to answer the native "turn on location" dialog.
  static const _positionTimeoutAfterServiceDialog = Duration(seconds: 60);

  @override
  Future<LocationAccessStatus> checkAccessStatus() async {
    try {
      final permission = await geolocator.Geolocator.checkPermission();
      return await _statusFor(permission);
    } on Exception {
      return LocationAccessStatus.unavailable;
    }
  }

  @override
  Future<LocationAccessStatus> requestPermission() async {
    try {
      var permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
      }
      return await _statusFor(permission);
    } on Exception {
      return LocationAccessStatus.unavailable;
    }
  }

  @override
  Stream<bool> serviceStatusStream() {
    return geolocator.Geolocator.getServiceStatusStream().map(
      (status) => status == geolocator.ServiceStatus.enabled,
    );
  }

  @override
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
    bool resolveServiceIfDisabled = false,
  }) async {
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

    final serviceEnabled =
        await geolocator.Geolocator.isLocationServiceEnabled();
    final canResolveService =
        resolveServiceIfDisabled &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android;
    if (!serviceEnabled && !canResolveService) {
      throw const LocationServiceDisabledException();
    }

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: serviceEnabled
              ? _positionTimeout
              : _positionTimeoutAfterServiceDialog,
        ),
      );

      return AppPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on geolocator.LocationServiceDisabledException {
      throw const LocationServiceDisabledException();
    } on geolocator.PermissionDeniedException {
      throw const LocationPermissionDeniedException();
    } on Exception {
      throw const LocationUnavailableException();
    }
  }

  Future<LocationAccessStatus> _statusFor(
    geolocator.LocationPermission permission,
  ) async {
    switch (permission) {
      case geolocator.LocationPermission.denied:
        return LocationAccessStatus.permissionDenied;
      case geolocator.LocationPermission.deniedForever:
        return LocationAccessStatus.permissionDeniedForever;
      case geolocator.LocationPermission.unableToDetermine:
        return LocationAccessStatus.unavailable;
      case geolocator.LocationPermission.whileInUse:
      case geolocator.LocationPermission.always:
        final serviceEnabled =
            await geolocator.Geolocator.isLocationServiceEnabled();
        return serviceEnabled
            ? LocationAccessStatus.granted
            : LocationAccessStatus.serviceDisabled;
    }
  }
}
