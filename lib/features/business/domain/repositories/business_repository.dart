import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ournego/features/business/domain/entitites/app_schedule.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';

import '../../../../core/failures.dart';

abstract class BusinessRepository {
  Future<Either<Failure, bool>> isLoggedIn();

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
    required File image,
    required String phoneNumber,
    required List<AppSchedule> hours,
  });

  Future<Either<Failure, bool>> checkIfOwner();
}
