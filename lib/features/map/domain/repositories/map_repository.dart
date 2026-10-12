import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/entities/business.dart';

abstract class MapRepository {
  Future<LocationAccessStatus> checkLocationAccessStatus();
  Future<LocationAccessStatus> requestLocationPermission();
  Stream<bool> watchLocationService();
  Future<Either<Failure, AppPosition>> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
    bool resolveServiceIfDisabled = false,
  });
  Stream<List<Business>> getBusinesses();
  Future<Either<Failure, Business?>> getBusinessById(String businessId);
  Future<Either<Failure, void>> addBusinessToFavorites(String businessId);
  Future<Either<Failure, void>> removeBusinessFromFavorites(String businessId);
  Stream<bool> isBusinessFavorite(String businessId);
  Future<Either<Failure, void>> trackBusinessVisit({
    required String businessId,
    required String source,
  });
}

// TODO: Consider adding pagination/filtering to `getBusinesses`.
// Perspective: For large datasets, streaming everything at once is
// inefficient; provide queries with bounding box or proximity filters.
