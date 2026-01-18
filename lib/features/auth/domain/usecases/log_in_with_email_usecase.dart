import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class LogInWithEmailUsecase {
  final AuthRepository repository;

  LogInWithEmailUsecase({required this.repository});

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) async {
    return repository.logInWithEmail(email, password);
  }
}
