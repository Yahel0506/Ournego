import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/repositories/manual_zone_repository.dart';

class ResolveZoneFromPointUsecase {
  final ManualZoneRepository repository;

  ResolveZoneFromPointUsecase({required this.repository});

  Future<ManualZone> call(AppPosition position) {
    return repository.resolveZoneFromPoint(position);
  }
}
