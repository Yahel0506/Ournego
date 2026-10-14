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
  int _pendingOperations = 0;

  @override
  Future<MapLocationState> build() async {
    _watchLocationService();

    _pendingOperations++;
    final List<Object?> results;
    try {
      results = await Future.wait([_resolve(), _loadSavedZone()]);
    } finally {
      _pendingOperations--;
    }
    final initial = MapLocationState(
      status: LocationAccessStatus.unavailable,
      manualZone: results[1] as ManualZone?,
    );
    return _apply(initial, results[0] as _Outcome);
  }

  void _watchLocationService() {
    try {
      final subscription = ref
          .read(watchLocationServiceUsecaseProvider)()
          .listen(_onServiceChanged, onError: (Object _) {});
      ref.onDispose(subscription.cancel);
    } catch (_) {
      // Without service updates the map still works; it just rechecks on
      // resume and on user actions.
    }
  }

  /// Re-reads permission and service state (never prompts) and refreshes the
  /// GPS fix. Call it when the app returns to the foreground.
  ///
  /// While the user has already declined the system's "turn on location"
  /// dialog for the current outage it does nothing, unless [force] is set:
  /// coming back from that dialog also counts as returning to the app, and
  /// re-reading the position would open it again.
  Future<void> recheck({bool force = false}) {
    if (!force) {
      final current = state.value;
      // Nothing to refresh yet, or another read is already running (the
      // dialog's own lifecycle echo can arrive before its result does).
      if (current == null || _pendingOperations > 0) {
        return Future<void>.value();
      }
      if (current.status == LocationAccessStatus.serviceDisabled &&
          current.serviceDialogOffered) {
        return Future<void>.value();
      }
    }
    return _update(_resolve);
  }

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
        (failure) => _outcomeFromFailure(failure, dialogAlreadyOffered: true),
        (position) => _Outcome(
          status: LocationAccessStatus.granted,
          gpsPosition: position,
        ),
      );
    });
  }

  /// Uses [zone] as the reference when there is no GPS fix, and remembers it.
  Future<void> setManualZone(ManualZone zone) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(manualZone: zone));
    await ref.read(saveManualZoneUsecaseProvider)(zone);
  }

  Future<void> clearManualZone() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearManualZone: true));
    await ref.read(clearManualZoneUsecaseProvider)();
  }

  Future<ManualZone?> _loadSavedZone() async {
    try {
      final result = await ref.read(getManualZoneUsecaseProvider)();
      return result.fold((_) => null, (zone) => zone);
    } catch (_) {
      return null;
    }
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
          serviceDialogOffered: false,
        ),
      );
      return;
    }

    unawaited(recheck(force: true));
  }

  Future<void> _update(Future<_Outcome> Function() compute) async {
    final generation = ++_generation;
    _pendingOperations++;
    final _Outcome outcome;
    try {
      outcome = await compute();
    } finally {
      _pendingOperations--;
    }
    // A newer operation (or a service change) already decided the state.
    if (generation != _generation) return;

    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(_apply(latest, outcome));
  }

  MapLocationState _apply(MapLocationState base, _Outcome outcome) {
    final stillOutOfService =
        outcome.status == LocationAccessStatus.serviceDisabled &&
        base.status == LocationAccessStatus.serviceDisabled;
    return base.copyWith(
      status: outcome.status,
      gpsPosition: outcome.gpsPosition,
      clearGpsPosition: outcome.gpsPosition == null && !outcome.keepGps,
      serviceDialogOffered:
          outcome.serviceDialogOffered ||
          (stillOutOfService && base.serviceDialogOffered),
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
      (failure) => _outcomeFromFailure(failure, dialogAlreadyOffered: true),
      (position) =>
          _Outcome(status: LocationAccessStatus.granted, gpsPosition: position),
    );
  }

  /// [dialogAlreadyOffered] is true when the failed attempt ran with the
  /// location service on (or asked the system to turn it on), so a
  /// `serviceDisabled` result means the user declined the native dialog.
  _Outcome _outcomeFromFailure(
    Failure failure, {
    bool dialogAlreadyOffered = false,
  }) {
    if (failure is LocationPermissionDeniedFailure) {
      return const _Outcome(status: LocationAccessStatus.permissionDenied);
    }
    if (failure is LocationPermissionDeniedForeverFailure) {
      return const _Outcome(
        status: LocationAccessStatus.permissionDeniedForever,
      );
    }
    if (failure is LocationServiceDisabledFailure) {
      return _Outcome(
        status: LocationAccessStatus.serviceDisabled,
        serviceDialogOffered: dialogAlreadyOffered,
      );
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

  /// The system's native "turn on location" dialog was shown and declined.
  final bool serviceDialogOffered;

  const _Outcome({
    required this.status,
    this.gpsPosition,
    this.keepGps = false,
    this.serviceDialogOffered = false,
  });
}
