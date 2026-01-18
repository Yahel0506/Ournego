import 'dart:async';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class MapNotifier extends AsyncNotifier<AppPosition> {
  @override
  FutureOr<AppPosition> build() async {
    final permissionGranted = await Permission.location.isGranted;

    if (permissionGranted) {
      final usecase = ref.read(getCurrentLocationUsecaseProvider);
      final result = await usecase();

      return result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          throw failure;
        },
        (position) {
          return position;
        },
      );
    } else {
      final permissionDeniedForever =
          await Permission.location.isPermanentlyDenied;

      if (permissionDeniedForever) {
        throw LocationPermissionDeniedForeverFailure();
      } else {
        throw LocationPermissionDeniedFailure();
      }
    }
  }
}
