import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class FakeMapRepository implements MapRepository {
  FakeMapRepository({
    Either<Failure, AppPosition>? locationResult,
    List<Business>? initialBusinesses,
    Map<String, Business>? businessById,
  }) : _locationResult =
           locationResult ??
           Right(AppPosition(latitude: 19.4326, longitude: -99.1332)),
       _businessesController = StreamController<List<Business>>.broadcast() {
    _businesses = List<Business>.from(initialBusinesses ?? const []);
    _businessById = {
      for (final business in _businesses) business.id: business,
      ...?businessById,
    };
    _businessesController.add(_businesses);
  }

  Either<Failure, AppPosition> _locationResult;
  late List<Business> _businesses;
  late Map<String, Business> _businessById;
  final StreamController<List<Business>> _businessesController;

  void setLocationResult(Either<Failure, AppPosition> result) {
    _locationResult = result;
  }

  void setBusinesses(List<Business> businesses) {
    _businesses = List<Business>.from(businesses);
    _businessById = {for (final business in _businesses) business.id: business};
    _businessesController.add(_businesses);
  }

  void setBusinessById(Business business) {
    _businessById[business.id] = business;
  }

  @override
  Future<Either<Failure, AppPosition>> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    return _locationResult;
  }

  @override
  Stream<List<Business>> getBusinesses() => _businessesController.stream;

  @override
  Future<Either<Failure, Business?>> getBusinessById(
    String businessId,
  ) async {
    return Right(_businessById[businessId]);
  }

  @override
  Future<Either<Failure, void>> addBusinessToFavorites(
    String businessId,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeBusinessFromFavorites(
    String businessId,
  ) async {
    return const Right(null);
  }

  @override
  Stream<bool> isBusinessFavorite(String businessId) {
    return Stream<bool>.value(false);
  }

  Future<void> dispose() async {
    await _businessesController.close();
  }
}
