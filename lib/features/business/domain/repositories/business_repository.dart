import 'package:dartz/dartz.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';

import '../../../../core/failures.dart';

abstract class BusinessRepository {
  Future<Either<Failure, List<AppPosition>>> getAddressesSuggestions(
    String query,
  );

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
  });

  Future<Either<Failure, bool>> checkIfOwner();

  Future<Either<Failure, void>> upsertBusinessName({
    required String businessId,
    required String name,
  });

  Future<Either<Failure, void>> upsertBusinessDescription({
    required String businessId,
    required String description,
  });

  Future<Either<Failure, void>> upsertBusinessLocation({
    required String businessId,
    required String address,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, void>> upsertBusinessCategory({
    required String businessId,
    required int category,
  });

  Future<Either<Failure, void>> insertBusinessImage({
    required String businessId,
    required BusinessImageData image,
  });

  Future<Either<Failure, void>> deleteBusinessImage({
    required String businessId,
    required String imageUrl,
  });

  Future<Either<Failure, void>> upsertBusinessPhoneNumber({
    required String businessId,
    required String phoneNumber,
  });

  Future<Either<Failure, void>> deleteBusinessPhoneNumber({
    required String businessId,
  });
}
