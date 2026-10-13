import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/repositories/manual_zone_repository.dart';

class SearchZoneSuggestionsUsecase {
  final ManualZoneRepository repository;

  SearchZoneSuggestionsUsecase({required this.repository});

  Future<Either<Failure, List<ManualZone>>> call(String query) {
    return repository.searchZones(query);
  }
}
