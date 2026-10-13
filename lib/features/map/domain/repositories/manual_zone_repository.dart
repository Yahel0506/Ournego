import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';

abstract class ManualZoneRepository {
  /// Zones matching [query]. Short queries return an empty list without
  /// hitting the network. Fails with [NetworkFailure] when offline.
  Future<Either<Failure, List<ManualZone>>> searchZones(String query);

  /// Names the place at [position]. Never fails because of the network: when
  /// the place cannot be resolved the zone gets a generic label.
  Future<ManualZone> resolveZoneFromPoint(AppPosition position);

  Future<Either<Failure, ManualZone?>> getSavedZone();
  Future<Either<Failure, void>> saveZone(ManualZone zone);
  Future<Either<Failure, void>> clearSavedZone();
}
