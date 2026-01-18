import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/entities/auth_selection.dart';
//import 'package:ournego/features/auth/domain/entities/google_auth.dart';

abstract class AuthRepository {
  // Obtener datos de textos y vistas de la UI (Local)
  AuthSelection getAuthSelectionView();

  // Funciones provenientes del servidor (Server)
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
  );

  Future<Either<Failure, AppUser>> logInWithEmail(
    String email,
    String password,
  );

  Future<Either<Failure, void>> updateProfilePicture(File profilePicture);

  Future<Either<Failure, void>> updateUserName(String name);

  Stream<AppUser> getProfile({String? userId});

  Future<Either<Failure, void>> confirmHasProfile();

  Future<Either<Failure, bool>> checkHasProfile();
}
