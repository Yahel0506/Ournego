import 'package:dartz/dartz.dart';

import '../../../../core/failures.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUsecase {
  final AuthRepository repository;

  SignInWithGoogleUsecase(this.repository);

  Future<Either<Failure, void>> call() async {
    return repository.signInWithGoogle();
  }
}
