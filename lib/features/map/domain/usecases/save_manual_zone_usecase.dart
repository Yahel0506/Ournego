import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/repositories/manual_zone_repository.dart';

class SaveManualZoneUsecase {
  final ManualZoneRepository repository;

  SaveManualZoneUsecase({required this.repository});

  Future<Either<Failure, void>> call(ManualZone zone) {
    return repository.saveZone(zone);
  }
}
