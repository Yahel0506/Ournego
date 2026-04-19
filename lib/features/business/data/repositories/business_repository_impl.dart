import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/business/data/datasources/business_geocoding_datasource.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/data/errors/business_registration_exceptions.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessSupabaseDatasource businessDatasource;
  final BusinessGeocodingDatasource geocodingDatasource;

  BusinessRepositoryImpl({
    required this.businessDatasource,
    required this.geocodingDatasource,
  });

  @override
  Future<Either<Failure, List<AppPosition>>> getAddressesSuggestions(
    String query,
  ) async {
    try {
      final suggestions = await geocodingDatasource.getAddressSuggestions(
        query,
      );
      final List<AppPosition> locations = suggestions.map((suggestion) {
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
    } catch (e, stackTrace) {
      debugPrint('Error getting address suggestions: $e');
      debugPrint('$stackTrace');
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
    required BusinessImageData image,
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
      await businessDatasource.setBusinessHours(businessId, hours);

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
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkIfOwner() async {
    try {
      final isOwner = await businessDatasource.checkIfOwner();
      return Right(isOwner);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> upsertBusinessName({
    required String businessId,
    required String name,
  }) async {
    try {
      await businessDatasource.upsertBusinessName(
        businessId: businessId,
        name: name,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> upsertBusinessDescription({
    required String businessId,
    required String description,
  }) async {
    try {
      await businessDatasource.upsertBusinessDescription(
        businessId: businessId,
        description: description,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> upsertBusinessLocation({
    required String businessId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await businessDatasource.upsertBusinessLocation(
        businessId: businessId,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> upsertBusinessCategory({
    required String businessId,
    required int category,
  }) async {
    try {
      await businessDatasource.upsertBusinessCategory(
        businessId: businessId,
        category: category,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> insertBusinessImage({
    required String businessId,
    required BusinessImageData image,
  }) async {
    try {
      await businessDatasource.insertBusinessImage(
        businessId: businessId,
        image: image,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationImageUploadException {
      return Left(BusinessRegistrationImageUploadFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteBusinessImage({
    required String businessId,
    required String imageUrl,
  }) async {
    try {
      await businessDatasource.deleteBusinessImage(
        businessId: businessId,
        imageUrl: imageUrl,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationImageUploadException {
      return Left(BusinessRegistrationImageUploadFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> upsertBusinessPhoneNumber({
    required String businessId,
    required String phoneNumber,
  }) async {
    try {
      await businessDatasource.upsertBusinessPhoneNumber(
        businessId: businessId,
        phoneNumber: phoneNumber,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteBusinessPhoneNumber({
    required String businessId,
  }) async {
    try {
      await businessDatasource.deleteBusinessPhoneNumber(
        businessId: businessId,
      );
      return const Right(null);
    } on BusinessRegistrationUnauthorizedException {
      return Left(BusinessRegistrationUnauthorizedFailure());
    } on BusinessRegistrationValidationException {
      return Left(BusinessRegistrationValidationFailure());
    } on BusinessRegistrationNetworkException {
      return Left(BusinessRegistrationNetworkFailure());
    } catch (_) {
      return Left(BusinessRegistrationUnknownFailure());
    }
  }
}
