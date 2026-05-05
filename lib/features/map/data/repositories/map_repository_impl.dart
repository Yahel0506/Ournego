import 'package:dartz/dartz.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/data/datasources/map_exceptions.dart';
import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';
import 'package:ournego/features/map/data/models/business_model.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
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

    return businesses.map((data) {
      return data.map((businesses) {
        return BusinessModel.fromSupabase(businesses);
      }).toList();
    });
  }

  @override
  Future<Either<Failure, Business?>> getBusinessById(
    String businessId,
  ) async {
    try {
      final data = await businessesDatasource.getBusinessById(businessId);
      if (data == null) {
        return const Right(null);
      }

      final business = BusinessModel.fromSupabase(data);
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
}
