/*import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:ournego/features/auth/data/datasources/firestore_auth_datasource.dart';
import 'package:ournego/features/auth/data/datasources/local_auth_selection_datasource.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/entities/auth_selection.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final LocalAuthSelectionDatasource authSelectionDatasource;
  final FirestoreAuthDatasource databaseDatasource;
  final FirebaseAuthDatasource authDatasource;

  FirebaseAuthRepositoryImpl({
    required this.authSelectionDatasource,
    required this.databaseDatasource,
    required this.authDatasource,
  });

  @override
  AuthSelection getAuthSelectionView() {
    return authSelectionDatasource.getHardcodedAuthSelection();
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      final rawUser = await authDatasource.signUpWithEmail(email, password);

      AppUser user = AppUser(uid: rawUser.uid, email: rawUser.email);

      await databaseDatasource.createUserDoc(user);

      return Right(user);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> logInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final rawUser = await authDatasource.logInWithEmail(email, password);

      AppUser user = AppUser(uid: rawUser.uid, email: rawUser.email);

      final snapshot = await databaseDatasource.getUserDoc(user);

      if (!snapshot.exists) {
        return Left(UserProfileNotFound());
      }

      final data = snapshot.data();
      if (data == null) {
        return Left(ServerFailure());
      } else {
        user.name = (data as Map<String, dynamic>)['name'];
      }

      return Right(user);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          return Left(InvalidCredentialsFailure());
        default:
          debugPrint(e.code);
          return Left(ServerFailure());
      }
    } catch (_) {
      return Left(ServerFailure());
    }
  }
}*/
