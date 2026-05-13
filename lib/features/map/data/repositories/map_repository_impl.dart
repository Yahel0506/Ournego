import 'package:dartz/dartz.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/data/datasources/map_exceptions.dart';
import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';
import 'package:ournego/features/map/data/models/business_model.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final LocationDatasource geolocationDatasource;
  final SupabaseMapDatasource businessesDatasource;

  MapRepositoryImpl({
    required this.geolocationDatasource,
    required this.businessesDatasource,
  });

  @override
  Future<Either<Failure, AppPosition>> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    try {
      final position = await geolocationDatasource.getCurrentLocation(
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      );
      return Right(position);
    } on LocationPermissionDeniedForeverException {
      return Left(LocationPermissionDeniedForeverFailure());
    } on LocationPermissionDeniedException {
      return Left(LocationPermissionDeniedFailure());
    } on LocationServiceDisabledException {
      return Left(LocationServiceDisabledFailure());
    } on LocationUnavailableException {
      return Left(LocationUnavailableFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Stream<List<Business>> getBusinesses() {
    final businesses = businessesDatasource.getBusinesses();

    return businesses.asyncMap((data) async {
      final businessRows = data
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      final businessIds = businessRows
          .map((row) => row['business_id'] as String?)
          .whereType<String>()
          .toList(growable: false);

      final hoursByBusinessId = await businessesDatasource
          .getBusinessHoursByBusinessId(businessIds);
      final visitCountsByBusinessId = await businessesDatasource
          .getBusinessVisitCountsByBusinessId(businessIds);

      return businessRows.map((businessRow) {
        final businessId = businessRow['business_id'] as String?;
        final List<BusinessHours> hours = businessId == null
            ? const <BusinessHours>[]
            : (hoursByBusinessId[businessId] ?? const <BusinessHours>[]);
        final visitCount = businessId == null
            ? 0
            : (visitCountsByBusinessId[businessId] ?? 0);

        return BusinessModel.fromSupabase(
          businessRow,
          visitCount: visitCount,
          hours: hours,
        );
      }).toList();
    });
  }

  @override
  Future<Either<Failure, Business?>> getBusinessById(String businessId) async {
    try {
      final data = await businessesDatasource.getBusinessById(businessId);
      if (data == null) {
        return const Right(null);
      }

      final hoursByBusinessId = await businessesDatasource
          .getBusinessHoursByBusinessId([businessId]);
      final visitCountsByBusinessId = await businessesDatasource
          .getBusinessVisitCountsByBusinessId([businessId]);

      final business = BusinessModel.fromSupabase(
        data,
        visitCount: visitCountsByBusinessId[businessId] ?? 0,
        hours: hoursByBusinessId[businessId] ?? const [],
      );
      return Right(business);
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addBusinessToFavorites(
    String businessId,
  ) async {
    try {
      await businessesDatasource.addBusinessToFavorites(businessId);
      return Right(null);
    } on MapAuthenticationRequiredException {
      return Left(AuthenticationRequiredFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeBusinessFromFavorites(
    String businessId,
  ) async {
    try {
      await businessesDatasource.removeBusinessFromFavorites(businessId);
      return Right(null);
    } on MapAuthenticationRequiredException {
      return Left(AuthenticationRequiredFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Stream<bool> isBusinessFavorite(String businessId) {
    final isFavorite = businessesDatasource.isBusinessFavorite(businessId);
    return isFavorite;
  }

  @override
  Future<Either<Failure, void>> trackBusinessVisit({
    required String businessId,
    required String source,
  }) async {
    try {
      await businessesDatasource.trackBusinessInteraction(
        businessId: businessId,
        source: source,
        interactionType: 'view_business_profile',
      );
      return const Right(null);
    } catch (_) {
      return Left(ServerFailure());
    }
  }
}
