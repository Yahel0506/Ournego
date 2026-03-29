import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
//import 'package:ournego/features/auth/domain/entities/google_auth.dart';

abstract class AuthRepository {
  // Funciones provenientes del servidor (Server)
  // TODO: Document expected errors and whether email/password are trimmed.
  // Perspective: Add parameter validation or use value objects for email
  // and password to avoid repeating validation across implementations.
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
  );

  Future<Either<Failure, AppUser>> logInWithEmail(
    String email,
    String password,
  );

  Future<Either<Failure, void>> signInWithGoogle();

  Future<Either<Failure, void>> updateProfilePicture(File profilePicture);

  Future<Either<Failure, void>> updateUserName(String name);

  // TODO: Clarify stream behavior: does it emit a value immediately?
  // Perspective: Consider returning `Stream<Either<Failure, AppUser>>`
  // to propagate errors through the stream.
  Stream<AppUser> getProfile({String? userId});

  Future<Either<Failure, void>> confirmHasProfile();

  Future<Either<Failure, bool>> checkHasProfile();

  Future<Either<Failure, void>> logOut();
}
