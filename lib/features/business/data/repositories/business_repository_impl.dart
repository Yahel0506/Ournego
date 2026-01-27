import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/data/datasources/business_geocoding_datasource.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/domain/entitites/app_schedule.dart';

import '../../../map/domain/entities/app_position.dart';
import '../../domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessSupabaseDatasource businessDatasource;
  final BusinessGeocodingDatasource geocodingDatasource;

  BusinessRepositoryImpl({
    required this.businessDatasource,
    required this.geocodingDatasource,
  });

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final session = await businessDatasource.isLoggedIn();
      final result = session != null;
      return Right(result);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<AppPosition>>> getAddressesSuggestions(
    String query,
  ) async {
    try {
      final suggestions = await geocodingDatasource.getAddressSuggestions(
        query,
      );
      final locations = suggestions.map((suggestion) {
        final name = suggestion['name'] ?? '';
        final city = suggestion['city'] ?? '';
        final state = suggestion['state'] ?? '';
        final country = suggestion['country'] ?? '';
        final lat = suggestion['lat'] ?? 0.0;
        final lon = suggestion['lon'] ?? 0.0;
        final address = [
          name,
          city,
          state,
          country,
        ].where((part) => part.isNotEmpty).join(', ');

        return AppPosition(latitude: lat, longitude: lon, address: address);
      }).toList();
      return Right(locations);
    } catch (e) {
      debugPrint('Error fetching address suggestions: ${e.toString()}');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerBusiness({
    required String name,
    required String description,
    required int category,
    required String address,
    required double latitude,
    required double longitude,
    required File image,
    required String phoneNumber,
    required List<AppSchedule> hours,
  }) async {
    try {
      final businessId = await businessDatasource.registerBusiness({
        'name': name,
        'description': description,
        'address': address,
        'type': category,
        'latitude': latitude,
        'longitude': longitude,
        'phone_number': phoneNumber,
      });

      await businessDatasource.uploadBusinessImage(image, businessId);
      //await businessDatasource.setBusinessHours(businessId, hours);

      return Right(null);
    } catch (e) {
      debugPrint('Error registering business: ${e.toString()}');
      return Left(ServerFailure());
    }
  }
}
