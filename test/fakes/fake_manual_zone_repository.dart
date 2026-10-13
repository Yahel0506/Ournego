import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/repositories/manual_zone_repository.dart';

class FakeManualZoneRepository implements ManualZoneRepository {
  FakeManualZoneRepository({this.savedZone});

  ManualZone? savedZone;
  List<ManualZone> searchResults = const [];
  Failure? searchFailure;
  final searchedQueries = <String>[];

  @override
  Future<Either<Failure, List<ManualZone>>> searchZones(String query) async {
    searchedQueries.add(query);
    final failure = searchFailure;
    if (failure != null) return Left(failure);
    return Right(searchResults);
  }

  @override
  Future<ManualZone> resolveZoneFromPoint(AppPosition position) async {
    return ManualZone(
      position: position,
      label: 'Zona seleccionada en el mapa',
    );
  }

  @override
  Future<Either<Failure, ManualZone?>> getSavedZone() async => Right(savedZone);

  @override
  Future<Either<Failure, void>> saveZone(ManualZone zone) async {
    savedZone = zone;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearSavedZone() async {
    savedZone = null;
    return const Right(null);
  }
}
