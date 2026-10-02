import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/features/business/domain/entities/business_panel_metrics.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class FakeBusinessRepository implements BusinessRepository {
  FakeBusinessRepository({this.isOwner = false, this.failOwnerCheck = false});

  bool isOwner;
  bool failOwnerCheck;

  @override
  Future<Either<Failure, List<AppPosition>>> getAddressesSuggestions(
    String query,
  ) async {
    return const Right([]);
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
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> checkIfOwner() async {
    if (failOwnerCheck) {
      return Left(ServerFailure());
    }

    return Right(isOwner);
  }

  @override
  Future<Either<Failure, OwnedBusinessProfile?>> getOwnedBusiness() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertBusinessName({
    required String businessId,
    required String name,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertBusinessDescription({
    required String businessId,
    required String description,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertBusinessLocation({
    required String businessId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertBusinessCategory({
    required String businessId,
    required int category,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> insertBusinessImage({
    required String businessId,
    required BusinessImageData image,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteBusinessImage({
    required String businessId,
    required String imageUrl,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertBusinessPhoneNumber({
    required String businessId,
    required String phoneNumber,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteBusinessPhoneNumber({
    required String businessId,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertBusinessHours({
    required String businessId,
    required List<AppSchedule> hours,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, BusinessPanelMetrics>> getBusinessPanelMetrics({
    required String businessId,
  }) async {
    return const Right(
      BusinessPanelMetrics(
        averageRating: 0,
        monthlyInteractions: 0,
        favoriteCount: 0,
      ),
    );
  }
}
