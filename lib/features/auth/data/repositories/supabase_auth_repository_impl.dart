import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementation of [AuthRepository] using Supabase.
///
/// This repository:
/// - Receives [UserModel] from the datasource (data layer)
/// - Returns [AppUser] entities to the domain layer
/// - Handles error mapping to domain [Failure] types
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDatasource authDatasource;

  AuthRepositoryImpl({required this.authDatasource});

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      // Datasource returns UserModel (extends AppUser)
      final userModel = await authDatasource.signUpWithEmail(email, password);
      // Return as AppUser (model IS-A entity)
      return Right(userModel);
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return Left(EmailAlreadyInUseFailure());
      }
      debugPrint('AuthException in signUpWithEmail: ${e.message}');
      return Left(ServerFailure());
    } on SignupException catch (e) {
      debugPrint('SignupException: ${e.message}');
      return Left(ServerFailure());
    } catch (e) {
      debugPrint('Unknown error in signUpWithEmail: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> logInWithEmail(
    String email,
    String password,
  ) async {
    try {
      // Datasource returns UserModel
      final userModel = await authDatasource.logInWithEmail(email, password);

      debugPrint('Login successful for user: ${userModel.email}');
      return Right(userModel);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return Left(InvalidCredentialsFailure());
      }
      if (e.message.contains('Email not confirmed')) {
        return Left(EmailNotVerifiedFailure());
      }
      debugPrint('AuthException in logInWithEmail: ${e.message}');
      return Left(ServerFailure());
    } on LoginException catch (e) {
      debugPrint('LoginException: ${e.message}');
      return Left(InvalidCredentialsFailure());
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Unknown error in logInWithEmail: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await authDatasource.signInWithGoogle();
      return const Right(null);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.message}');
      return Left(ServerFailure());
    } catch (e) {
      debugPrint('Unknown error in signInWithGoogle: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateProfilePicture(
    File profilePicture,
  ) async {
    try {
      await authDatasource.updateProfilePicture(profilePicture);
      return const Right(null);
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Error in updateProfilePicture: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUserName(String name) async {
    try {
      await authDatasource.updateUserName(name);
      return const Right(null);
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Error in updateUserName: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Stream<AppUser> getProfile({String? userId}) {
    // Datasource returns Stream<UserModel>, which IS-A Stream<AppUser>
    // due to inheritance, so we can return it directly
    return authDatasource.getProfileStream(id: userId);
  }

  @override
  Stream<bool> watchEmailVerificationStatus() {
    return authDatasource.watchEmailVerificationStatus().distinct();
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final isVerified = await authDatasource.isEmailVerified();
      return Right(isVerified);
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } on EmailVerificationException {
      return Left(ServerFailure());
    } catch (e) {
      debugPrint('Error in isEmailVerified: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resendEmailVerification(String email) async {
    try {
      await authDatasource.resendEmailVerification(email);
      return const Right(null);
    } on AuthException catch (e) {
      debugPrint('AuthException in resendEmailVerification: ${e.message}');
      return Left(ServerFailure());
    } catch (e) {
      debugPrint('Error in resendEmailVerification: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await authDatasource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      debugPrint('AuthException in sendPasswordResetEmail: ${e.message}');
      return Left(ServerFailure());
    } catch (e) {
      debugPrint('Error in sendPasswordResetEmail: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> confirmHasProfile() async {
    try {
      await authDatasource.confirmHasProfile();
      return const Right(null);
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Error in confirmHasProfile: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkHasProfile() async {
    try {
      final hasProfile = await authDatasource.checkHasProfile();
      return Right(hasProfile);
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Error in checkHasProfile: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await authDatasource.logOut();
      return const Right(null);
    } catch (e) {
      debugPrint('Error in logOut: $e');
      return Left(ServerFailure());
    }
  }
}
