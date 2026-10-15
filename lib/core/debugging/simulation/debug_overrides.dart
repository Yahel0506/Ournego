import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;

import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/simulated_auth_datasource.dart';
import 'package:ournego/core/debugging/simulation/simulated_location_datasource.dart';
import 'package:ournego/core/debugging/simulation/simulated_connectivity.dart';
import 'package:ournego/core/geocoding/geocoding_providers.dart';
import 'package:ournego/core/geocoding/locationiq_geocoding_datasource.dart';
import 'package:ournego/core/location/geolocator_location_datasource.dart';
import 'package:ournego/core/network/connectivity_providers.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';

/// Provider overrides that route the app through the simulator. Debug only.
List<Override> debugSimulationOverrides(
  DebugSimulationController controller,
  http.Client httpClient,
) => [
  debugSimulationControllerProvider.overrideWithValue(controller),
  connectivityStatusProvider.overrideWith(
    (ref) => simulatedConnectivityStream(ref),
  ),
  geolocationDatasourceProvider.overrideWith(
    (ref) => SimulatedLocationDatasource(
      controller: controller,
      real: GeolocatorLocationDatasource(),
    ),
  ),
  supabaseAuthDatasourceProvider.overrideWith(
    (ref) => SimulatedAuthDatasource(controller),
  ),
  locationIqGeocodingDatasourceProvider.overrideWith(
    (ref) => LocationIqGeocodingDatasource(client: httpClient),
  ),
];
