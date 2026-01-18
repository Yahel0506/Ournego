import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileUsecase {
  final AuthRepository repository;

  UpdateProfileUsecase({required this.repository});

  Future<Either<Failure, void>> updateProfilePicture(
    File profilePicture,
  ) async {
    return await repository.updateProfilePicture(profilePicture);
  }

  Future<Either<Failure, void>> updateUserName(String name) async {
    return await repository.updateUserName(name);
  }
}
