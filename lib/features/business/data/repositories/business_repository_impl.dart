import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/data/datasources/business_geocoding_datasource.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/data/errors/business_registration_exceptions.dart';
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
  Stream<bool> isLoggedIn() {
    final session = businessDatasource.isLoggedIn();
    final isLogged = session.map((currentSession) => currentSession != null);
    return isLogged;
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
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationDuplicateException {
      return Left(BusinessRegistrationDuplicateFailure());
    } on BusinessRegistrationImageUploadException {
      return Left(BusinessRegistrationImageUploadFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } on BusinessRegistrationUnknownException {
      return Left(BusinessRegistrationUnknownFailure());
    } catch (e) {
      debugPrint('Error registering business: ${e.toString()}');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkIfOwner() async {
    try {
      final isOwner = await businessDatasource.checkIfOwner();
      return Right(isOwner);
    } catch (e) {
      debugPrint('Error checking if owner: ${e.toString()}');
      return Left(ServerFailure());
    }
  }
}
