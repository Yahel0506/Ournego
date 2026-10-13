import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/geocoding/locationiq_geocoding_datasource.dart';

final locationIqGeocodingDatasourceProvider =
    Provider<LocationIqGeocodingDatasource>(
      (ref) => LocationIqGeocodingDatasource(),
    );
