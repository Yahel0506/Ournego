import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class HasProfileUsecase {
  final AuthRepository repository;

  HasProfileUsecase({required this.repository});

  Future<Either<Failure, void>> confirmHasProfile() async {
    return await repository.confirmHasProfile();
  }

  Future<Either<Failure, bool>> checkHasProfile() async {
    return await repository.checkHasProfile();
  }
}
