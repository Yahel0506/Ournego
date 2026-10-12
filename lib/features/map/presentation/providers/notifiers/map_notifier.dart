import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/entities/map_location_state.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';

/// Holds the map's location state. It never ends in an error: every failure is
/// translated into a [LocationAccessStatus], and a reference location always
/// exists (see [MapLocationState.reference]).
class MapNotifier extends AsyncNotifier<MapLocationState> {
  int _generation = 0;

  @override
  Future<MapLocationState> build() async {
    final subscription = ref
        .read(watchLocationServiceUsecaseProvider)()
        .listen(_onServiceChanged, onError: (Object _) {});
    ref.onDispose(subscription.cancel);

    const initial = MapLocationState(status: LocationAccessStatus.unavailable);
    return _apply(initial, await _resolve());
  }

  /// Re-reads permission and service state (never prompts) and refreshes the
  /// GPS fix. Call it when the app returns to the foreground.
  Future<void> recheck() => _update(_resolve);

  /// Shows the system permission dialog when it can still be shown.
  Future<void> requestPermission() {
    return _update(() async {
      final status = await ref.read(requestLocationPermissionUsecaseProvider)();
      if (status != LocationAccessStatus.granted) {
        return _Outcome(status: status);
      }
      return _fetchPosition();
    });
  }

  /// Asks the system to turn the location service on (native dialog on
  /// Android) and, if accepted, picks up the position.
  Future<void> enableLocationService() {
    return _update(() async {
      final result = await ref.read(enableLocationServiceUsecaseProvider)();
      return result.fold(
        _outcomeFromFailure,
        (position) => _Outcome(
          status: LocationAccessStatus.granted,
          gpsPosition: position,
        ),
      );
    });
  }

  void setManualZone(ManualZone zone) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(manualZone: zone));
  }

  void clearManualZone() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearManualZone: true));
  }

  void _onServiceChanged(bool enabled) {
    final current = state.value;
    if (current == null) return;

    if (!enabled) {
      if (current.status == LocationAccessStatus.permissionDenied ||
          current.status == LocationAccessStatus.permissionDeniedForever) {
        return;
      }
      _generation++;
      state = AsyncData(
        current.copyWith(
          status: LocationAccessStatus.serviceDisabled,
          clearGpsPosition: true,
        ),
      );
      return;
    }

    unawaited(recheck());
  }

  Future<void> _update(Future<_Outcome> Function() compute) async {
    final generation = ++_generation;
    final outcome = await compute();
    // A newer operation (or a service change) already decided the state.
    if (generation != _generation) return;

    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(_apply(latest, outcome));
  }

  MapLocationState _apply(MapLocationState base, _Outcome outcome) {
    return base.copyWith(
      status: outcome.status,
      gpsPosition: outcome.gpsPosition,
      clearGpsPosition: outcome.gpsPosition == null && !outcome.keepGps,
    );
  }

  Future<_Outcome> _resolve() async {
    final LocationAccessStatus status;
    try {
      status = await ref.read(checkLocationAccessUsecaseProvider)();
    } catch (_) {
      return const _Outcome(
        status: LocationAccessStatus.unavailable,
        keepGps: true,
      );
    }

    if (status == LocationAccessStatus.granted) {
      return _fetchPosition();
    }
    return _Outcome(
      status: status,
      keepGps: status == LocationAccessStatus.unavailable,
    );
  }

  Future<_Outcome> _fetchPosition() async {
    final result = await ref.read(getCurrentLocationUsecaseProvider)(
      requestPermissionIfNeeded: false,
    );
    return result.fold(
      _outcomeFromFailure,
      (position) =>
          _Outcome(status: LocationAccessStatus.granted, gpsPosition: position),
    );
  }

  _Outcome _outcomeFromFailure(Failure failure) {
    if (failure is LocationPermissionDeniedFailure) {
      return const _Outcome(status: LocationAccessStatus.permissionDenied);
    }
    if (failure is LocationPermissionDeniedForeverFailure) {
      return const _Outcome(
        status: LocationAccessStatus.permissionDeniedForever,
      );
    }
    if (failure is LocationServiceDisabledFailure) {
      return const _Outcome(status: LocationAccessStatus.serviceDisabled);
    }
    // Timeouts and unknown errors: keep whatever fix we already had.
    return const _Outcome(
      status: LocationAccessStatus.unavailable,
      keepGps: true,
    );
  }
}

class _Outcome {
  final LocationAccessStatus status;
  final AppPosition? gpsPosition;

  /// Keep the previous GPS fix when this outcome carries none.
  final bool keepGps;

  const _Outcome({
    required this.status,
    this.gpsPosition,
    this.keepGps = false,
  });
}
