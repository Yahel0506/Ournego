import 'dart:async';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';

/// Fixed position handed out while the location is simulated as granted.
const simulatedPosition = AppPosition(latitude: 19.7050, longitude: -103.4600);

/// [LocationDatasource] driven by [LocationMode]. The system dialogs are
/// replaced by the user's answer baked into the mode: the app asks as it
/// would, and the answer comes back without a real dialog.
class SimulatedLocationDatasource implements LocationDatasource {
  SimulatedLocationDatasource({
    required this.controller,
    required this.real,
    this.position = simulatedPosition,
  });

  final DebugSimulationController controller;
  final LocationDatasource real;
  final AppPosition position;

  LocationMode get _mode => controller.value.locationMode;

  /// The user accepted a prompt: from now on everything is granted.
  void _accept() => controller.update(
    controller.value.copyWith(locationMode: LocationMode.granted),
  );

  @override
  Future<LocationAccessStatus> checkAccessStatus() async {
    switch (_mode) {
      case LocationMode.real:
        return real.checkAccessStatus();
      case LocationMode.granted:
        return LocationAccessStatus.granted;
      case LocationMode.denied:
      case LocationMode.allowOnPrompt:
        return LocationAccessStatus.permissionDenied;
      case LocationMode.deniedForever:
        return LocationAccessStatus.permissionDeniedForever;
      case LocationMode.serviceDisabled:
      case LocationMode.enableOnPrompt:
        return LocationAccessStatus.serviceDisabled;
      case LocationMode.unavailable:
        return LocationAccessStatus.unavailable;
    }
  }

  @override
  Future<LocationAccessStatus> requestPermission() async {
    if (_mode == LocationMode.allowOnPrompt) _accept();
    if (_mode == LocationMode.real) return real.requestPermission();
    return checkAccessStatus();
  }

  @override
  Stream<bool> serviceStatusStream() {
    late StreamController<bool> out;
    StreamSubscription<bool>? realSubscription;
    var lastMode = _mode;

    void onController() {
      final mode = _mode;
      if (mode == lastMode) return;
      lastMode = mode;
      if (mode == LocationMode.real) {
        real.checkAccessStatus().then((status) {
          if (!out.isClosed) {
            out.add(status != LocationAccessStatus.serviceDisabled);
          }
        });
      } else {
        out.add(mode.serviceEnabled);
      }
    }

    out = StreamController<bool>(
      onListen: () {
        realSubscription = real.serviceStatusStream().listen((enabled) {
          if (_mode == LocationMode.real) out.add(enabled);
        }, onError: out.addError);
        controller.addListener(onController);
      },
      onCancel: () {
        controller.removeListener(onController);
        return realSubscription?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
    bool resolveServiceIfDisabled = false,
  }) async {
    switch (_mode) {
      case LocationMode.real:
        return real.getCurrentLocation(
          requestPermissionIfNeeded: requestPermissionIfNeeded,
          resolveServiceIfDisabled: resolveServiceIfDisabled,
        );
      case LocationMode.granted:
        return position;
      case LocationMode.denied:
        throw const LocationPermissionDeniedException();
      case LocationMode.allowOnPrompt:
        if (!requestPermissionIfNeeded) {
          throw const LocationPermissionDeniedException();
        }
        _accept();
        return position;
      case LocationMode.deniedForever:
        throw const LocationPermissionDeniedForeverException();
      case LocationMode.serviceDisabled:
        throw const LocationServiceDisabledException();
      case LocationMode.enableOnPrompt:
        if (!resolveServiceIfDisabled) {
          throw const LocationServiceDisabledException();
        }
        _accept();
        return position;
      case LocationMode.unavailable:
        throw const LocationUnavailableException();
    }
  }
}
