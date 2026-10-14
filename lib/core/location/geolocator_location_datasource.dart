import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:geolocator/geolocator.dart' as geolocator;

import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';

class GeolocatorLocationDatasource implements LocationDatasource {
  GeolocatorLocationDatasource({
    bool Function()? isAppActive,
    Duration positionTimeout = const Duration(seconds: 12),
    Duration timeoutTick = const Duration(milliseconds: 250),
  }) : _isAppActive = isAppActive ?? _defaultIsAppActive,
       _positionTimeout = positionTimeout,
       _timeoutTick = timeoutTick;

  final bool Function() _isAppActive;
  final Duration _positionTimeout;
  final Duration _timeoutTick;

  /// The system's "turn on location" dialog sends the app to `inactive`, so
  /// the time the user spends deciding must not count against the timeout.
  static bool _defaultIsAppActive() {
    try {
      final state = WidgetsBinding.instance.lifecycleState;
      return state == null || state == AppLifecycleState.resumed;
    } catch (_) {
      return true;
    }
  }

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
    try {
      return geolocator.Geolocator.getServiceStatusStream().map(
        (status) => status == geolocator.ServiceStatus.enabled,
      );
    } catch (_) {
      // Not every platform can report it (the web throws UnsupportedError).
      return const Stream<bool>.empty();
    }
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
      final position = await _currentPositionWhileActive();

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

  /// Like `getCurrentPosition(timeLimit: ...)`, but only the time the app is
  /// in the foreground counts, so answering a system dialog never times out.
  Future<geolocator.Position> _currentPositionWhileActive() {
    final completer = Completer<geolocator.Position>();
    var activeTime = Duration.zero;

    final timer = Timer.periodic(_timeoutTick, (timer) {
      if (!_isAppActive()) return;
      activeTime += _timeoutTick;
      if (activeTime >= _positionTimeout && !completer.isCompleted) {
        completer.completeError(
          TimeoutException('No location fix', _positionTimeout),
        );
      }
    });

    geolocator.Geolocator.getCurrentPosition(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
      ),
    ).then(
      (position) {
        if (!completer.isCompleted) completer.complete(position);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );

    return completer.future.whenComplete(timer.cancel);
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
