import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class GetCurrentLocationUsecase {
  final MapRepository repository;

  GetCurrentLocationUsecase({required this.repository});

  Future<Either<Failure, AppPosition>> call({
    bool requestPermissionIfNeeded = true,
  }) async {
    return repository.getCurrentLocation(
      requestPermissionIfNeeded: requestPermissionIfNeeded,
    );
  }
}
