import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:google_sign_in/google_sign_in.dart' as gsi;

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/network/network_error_classifier.dart';
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

  Failure _failureFor(Object error) {
    if (isNetworkError(error)) return NetworkFailure();
    if (isSessionExpiredError(error)) return SessionExpiredFailure();
    return ServerFailure();
  }

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
      return Left(_failureFor(e));
    } on SignupException catch (e) {
      debugPrint('SignupException: ${e.message}');
      return Left(_failureFor(e));
    } catch (e) {
      debugPrint('Unknown error in signUpWithEmail: $e');
      return Left(_failureFor(e));
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
      return Left(_failureFor(e));
    } on LoginException catch (e) {
      debugPrint('LoginException: ${e.message}');
      return Left(InvalidCredentialsFailure());
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Unknown error in logInWithEmail: $e');
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await authDatasource.signInWithGoogle();
      return const Right(null);
    } catch (e) {
      debugPrint('Error in signInWithGoogle: $e');
      return Left(googleSignInFailureFor(e));
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
      return Left(_failureFor(e));
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
      return Left(_failureFor(e));
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
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, void>> resendEmailVerification(String email) async {
    try {
      await authDatasource.resendEmailVerification(email);
      return const Right(null);
    } on AuthException catch (e) {
      debugPrint('AuthException in resendEmailVerification: ${e.message}');
      return Left(_failureFor(e));
    } catch (e) {
      debugPrint('Error in resendEmailVerification: $e');
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await authDatasource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      debugPrint('AuthException in sendPasswordResetEmail: ${e.message}');
      return Left(_failureFor(e));
    } catch (e) {
      debugPrint('Error in sendPasswordResetEmail: $e');
      return Left(_failureFor(e));
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
      return Left(_failureFor(e));
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
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await authDatasource.logOut();
      return const Right(null);
    } catch (e) {
      debugPrint('Error in logOut: $e');
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelMyDeletion() async {
    try {
      return Right(await authDatasource.cancelMyDeletion());
    } on NoAuthenticatedUserException {
      return Left(AuthenticationRequiredFailure());
    } catch (e) {
      debugPrint('Error in cancelMyDeletion: $e');
      return Left(_failureFor(e));
    }
  }
}

/// Maps an error thrown while signing in with Google to a domain [Failure].
///
/// The datasource declares its own `GoogleSignInException`, which shadows the
/// one from `google_sign_in`; the platform one is matched here through a
/// prefix import so its [gsi.GoogleSignInExceptionCode] is not lost.
@visibleForTesting
Failure googleSignInFailureFor(Object error) {
  if (error is gsi.GoogleSignInException) {
    switch (error.code) {
      case gsi.GoogleSignInExceptionCode.canceled:
        return GoogleSignInCancelledFailure();
      case gsi.GoogleSignInExceptionCode.clientConfigurationError:
      case gsi.GoogleSignInExceptionCode.providerConfigurationError:
      case gsi.GoogleSignInExceptionCode.uiUnavailable:
        return GoogleSignInUnavailableFailure();
      case gsi.GoogleSignInExceptionCode.interrupted:
      case gsi.GoogleSignInExceptionCode.userMismatch:
      case gsi.GoogleSignInExceptionCode.unknownError:
        return ServerFailure();
    }
  }
  if (isNetworkError(error)) return NetworkFailure();
  return ServerFailure();
}
