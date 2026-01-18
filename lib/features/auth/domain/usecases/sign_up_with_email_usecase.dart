import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmailUsecase {
  final AuthRepository repository;

  SignUpWithEmailUsecase({required this.repository});

  Future<Either<Failure, AppUser>> call(String email, String password) async {
    // Contacto con el repo
    return repository.signUpWithEmail(email, password);
  }
}
