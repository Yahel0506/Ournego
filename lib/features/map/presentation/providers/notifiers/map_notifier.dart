import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';

class MapNotifier extends AsyncNotifier<AppPosition> {
  @override
  FutureOr<AppPosition> build() async {
    return _loadCurrentLocation(requestPermissionIfNeeded: true);
  }

  Future<void> refreshLocation({bool requestPermissionIfNeeded = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadCurrentLocation(
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      ),
    );
  }

  Future<AppPosition> _loadCurrentLocation({
    required bool requestPermissionIfNeeded,
  }) async {
    final usecase = ref.read(getCurrentLocationUsecaseProvider);
    final result = await usecase(
      requestPermissionIfNeeded: requestPermissionIfNeeded,
    );

    return result.fold((failure) => throw failure, (position) => position);
  }
}
