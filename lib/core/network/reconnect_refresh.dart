import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/network/connectivity_providers.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';

/// Invalidates remote-data providers that may have failed while offline.
void refreshRemoteData(WidgetRef ref) {
  ref.invalidate(businessesStreamProvider);
  ref.invalidate(profileStreamProvider);
  ref.invalidate(isOwnerProvider);
  ref.invalidate(ownedBusinessProvider);
}

/// Calls [onReconnect] on every offline → online transition.
void listenForReconnect(WidgetRef ref, void Function() onReconnect) {
  ref.listen<bool>(isOnlineProvider, (previous, next) {
    if (previous == false && next) onReconnect();
  });
}
