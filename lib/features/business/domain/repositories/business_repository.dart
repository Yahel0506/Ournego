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
}
