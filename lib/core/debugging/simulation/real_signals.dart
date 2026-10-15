import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/location/geolocator_location_datasource.dart';
import 'package:ournego/core/location/location_access_status.dart';

/// What the device and the backend really report, ignoring any simulation.
class RealSignals {
  const RealSignals({
    required this.supabaseReady,
    required this.hasSession,
    required this.deviceOnline,
    required this.location,
  });

  final bool supabaseReady;
  final bool hasSession;

  /// Null when it could not be read.
  final bool? deviceOnline;
  final LocationAccessStatus location;
}

typedef RealSignalsReader = Future<RealSignals> Function();

// LAYER 1: Datasources
final realSignalsReaderProvider = Provider<RealSignalsReader>((ref) {
  return readRealSignals;
});

Future<RealSignals> readRealSignals() async {
  var supabaseReady = false;
  var hasSession = false;
  try {
    supabaseReady = Supabase.instance.isInitialized;
    hasSession = Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    // Not initialized: the startup error screen is showing.
  }

  bool? online;
  try {
    final results = await Connectivity().checkConnectivity();
    online = results.any((result) => result != ConnectivityResult.none);
  } catch (_) {
    online = null;
  }

  // Always the real datasource, never the simulated one.
  var location = LocationAccessStatus.unavailable;
  try {
    location = await GeolocatorLocationDatasource().checkAccessStatus();
  } catch (_) {
    // Keep `unavailable`.
  }

  return RealSignals(
    supabaseReady: supabaseReady,
    hasSession: hasSession,
    deviceOnline: online,
    location: location,
  );
}
