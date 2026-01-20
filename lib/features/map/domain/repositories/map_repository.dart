import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/features/map/domain/entities/business.dart';

abstract class MapRepository {
  Future<Either<Failure, AppPosition>> getCurrentLocation();
  Stream<List<Business>> getBusinesses();
  Future<Either<Failure, void>> addBusinessToFavorites(String businessId);
  Future<Either<Failure, void>> removeBusinessFromFavorites(String businessId);
  Stream<bool> isBusinessFavorite(String businessId);
}

// TODO: Consider adding pagination/filtering to `getBusinesses` and a
// `getBusinessById` method. Perspective: For large datasets, streaming
// everything at once is inefficient; provide queries with bounding box
// or proximity filters.
