import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/data/datasources/geolocator_datasource.dart';
import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';
import 'package:ournego/features/map/data/models/business_model.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final GeolocatorDatasource geolocationDatasource;
  final SupabaseMapDatasource businessesDatasource;
  final FirebaseFirestore firestore;

  MapRepositoryImpl({
    required this.geolocationDatasource,
    required this.businessesDatasource,
    required this.firestore,
  });

  @override
  Future<Either<Failure, AppPosition>> getCurrentLocation() async {
    try {
      final position = await geolocationDatasource.getCurrentLocation();
      return Right(
        AppPosition(latitude: position.latitude, longitude: position.longitude),
      );
    } on Exception {
      return Left(LocationPermissionDeniedFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }
  /*
  @override
  Stream<List<Business>> getBusinesses() {
    return firestore.collection('businesses').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BusinessModel.fromFirestore(doc))
          .toList();
    });
  }*/

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
  Future<Either<Failure, void>> addBusinessToFavorites(String businessId) async {
    try {
      await businessesDatasource.addBusinessToFavorites(businessId);
      return Right(null);
    } on Exception catch (e) {
      if (e.toString().contains('no-authenticated-user')) {
        return Left(AuthenticationRequiredFailure());
      }
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeBusinessFromFavorites(String businessId) async {
    try {
      await businessesDatasource.removeBusinessFromFavorites(businessId);
      return Right(null);
    } on Exception catch (e) {
      if (e.toString().contains('no-authenticated-user')) {
        return Left(AuthenticationRequiredFailure());
      }
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Stream<bool> isBusinessFavorite(String businessId)  {
      final isFavorite =  businessesDatasource.isBusinessFavorite(businessId);
      return isFavorite;
  }
}
