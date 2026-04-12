import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class FakeBusinessRepository implements BusinessRepository {
  FakeBusinessRepository({
    this.isOwner = false,
    this.failOwnerCheck = false,
  });

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
    required File image,
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
}
