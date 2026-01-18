import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/features/map/domain/entities/business.dart';

abstract class MapRepository {
  Future<Either<Failure, AppPosition>> getCurrentLocation();
  Stream<List<Business>> getBusinesses();
}
