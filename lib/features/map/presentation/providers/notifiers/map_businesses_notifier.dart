import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';

/// What the map shows for businesses: the latest list delivered, kept even
/// while the live stream is failing or reloading.
class MapBusinesses {
  const MapBusinesses({this.businesses, this.loadFailed = false});

  /// Last list received in this app run; null until the first load succeeds.
  final List<Business>? businesses;

  /// The live stream is currently in an error state.
  final bool loadFailed;

  bool get hasBusinesses => businesses != null;

  /// The list on screen may be out of date: it is a leftover from before the
  /// stream failed.
  bool get isStale => hasBusinesses && loadFailed;
}

/// Keeps the last businesses in memory only (OUR-150): a cold start without
/// network still shows the load error and its retry. Disk retention would
/// need a serialized copy of businesses and hours that can outlive removals.
class MapBusinessesNotifier extends Notifier<MapBusinesses> {
  @override
  MapBusinesses build() {
    ref.listen(businessesStreamProvider, (_, next) {
      state = _fold(state, next);
    });
    return _fold(const MapBusinesses(), ref.read(businessesStreamProvider));
  }

  MapBusinesses _fold(MapBusinesses previous, AsyncValue<List<Business>> raw) {
    final data = raw.asData;
    if (data != null) return MapBusinesses(businesses: data.value);
    return MapBusinesses(
      businesses: previous.businesses,
      loadFailed: raw.hasError,
    );
  }
}
