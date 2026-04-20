import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class EmailVerificationUsecase {
  final AuthRepository repository;

  EmailVerificationUsecase({required this.repository});

  Stream<bool> watchVerificationStatus() {
    return repository.watchEmailVerificationStatus();
  }

  Future<Either<Failure, bool>> isEmailVerified() async {
    return repository.isEmailVerified();
  }

  Future<Either<Failure, void>> resendVerificationEmail(String email) async {
    return repository.resendEmailVerification(email);
  }
}
