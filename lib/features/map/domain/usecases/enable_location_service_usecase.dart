import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

/// Asks for a position while letting the system offer to turn on the device
/// location service (native dialog on Android).
class EnableLocationServiceUsecase {
  final MapRepository repository;

  EnableLocationServiceUsecase({required this.repository});

  Future<Either<Failure, AppPosition>> call() {
    return repository.getCurrentLocation(
      requestPermissionIfNeeded: false,
      resolveServiceIfDisabled: true,
    );
  }
}
