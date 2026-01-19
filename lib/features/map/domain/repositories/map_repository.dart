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
