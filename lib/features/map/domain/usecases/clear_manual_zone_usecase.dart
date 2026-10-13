import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/repositories/manual_zone_repository.dart';

class ClearManualZoneUsecase {
  final ManualZoneRepository repository;

  ClearManualZoneUsecase({required this.repository});

  Future<Either<Failure, void>> call() => repository.clearSavedZone();
}
