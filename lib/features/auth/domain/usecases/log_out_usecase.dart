import 'package:dartz/dartz.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

import '../../../../core/failures.dart';

class LogOutUsecase {
  final AuthRepository repository;

  LogOutUsecase({required this.repository});

  Future<Either<Failure, void>> call() {
    return repository.logOut();
  }
}
