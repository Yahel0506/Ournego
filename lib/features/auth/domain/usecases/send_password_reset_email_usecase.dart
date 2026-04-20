import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmailUsecase {
  final AuthRepository repository;

  SendPasswordResetEmailUsecase({required this.repository});

  Future<Either<Failure, void>> call(String email) async {
    return repository.sendPasswordResetEmail(email);
  }
}
