import 'package:dartz/dartz.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

import '../../../../core/failures.dart';

class CheckIfLoggedUsecase {
  final BusinessRepository repository;

  CheckIfLoggedUsecase(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.isLoggedIn();
  }
}
