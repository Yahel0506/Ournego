import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

import '../fixtures/mock_users.dart';

enum FakeAuthState {
  unauthenticated,
  authenticatedAsCustomer,
  authenticatedAsOwnerWithBusiness,
  authenticatedAsOwnerWithoutBusiness,
  expiredToken,
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.state = FakeAuthState.unauthenticated,
    this.forceInvalidCredentials = false,
    this.forceNoConnection = false,
    this.forceSuspendedAccount = false,
    this.onLogin,
    this.onLogout,
  });

  FakeAuthState state;
  bool forceInvalidCredentials;
  bool forceNoConnection;
  bool forceSuspendedAccount;
  final void Function(FakeAuthState state)? onLogin;
  final void Function()? onLogout;

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
  ) async {
    return Left(ServerFailure());
  }

  @override
  Future<Either<Failure, AppUser>> logInWithEmail(
    String email,
    String password,
  ) async {
    if (forceNoConnection) {
      return Left(ServerFailure());
    }

    if (forceSuspendedAccount) {
      return Left(ServerFailure());
    }

    if (forceInvalidCredentials ||
        email != MockCredentials.validEmail ||
        password != MockCredentials.validPassword) {
      return Left(InvalidCredentialsFailure());
    }

    switch (state) {
      case FakeAuthState.authenticatedAsCustomer:
        onLogin?.call(state);
        return Right(MockUsers.customer);
      case FakeAuthState.authenticatedAsOwnerWithBusiness:
        onLogin?.call(state);
        return Right(MockUsers.ownerWithBusiness);
      case FakeAuthState.authenticatedAsOwnerWithoutBusiness:
        onLogin?.call(state);
        return Right(MockUsers.ownerWithoutBusiness);
      case FakeAuthState.expiredToken:
        return Left(AuthenticationRequiredFailure());
      case FakeAuthState.unauthenticated:
        return Left(InvalidCredentialsFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    return Left(ServerFailure());
  }

  @override
  Future<Either<Failure, void>> updateProfilePicture(
    File profilePicture,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateUserName(String name) async {
    return const Right(null);
  }

  @override
  Stream<AppUser> getProfile({String? userId}) {
    final user = switch (state) {
      FakeAuthState.authenticatedAsCustomer => MockUsers.customer,
      FakeAuthState.authenticatedAsOwnerWithBusiness =>
        MockUsers.ownerWithBusiness,
      FakeAuthState.authenticatedAsOwnerWithoutBusiness =>
        MockUsers.ownerWithoutBusiness,
      FakeAuthState.expiredToken => MockUsers.expiredSessionUser,
      FakeAuthState.unauthenticated => const AppUser(uid: 'anonymous'),
    };

    return Stream<AppUser>.value(user);
  }

  @override
  Stream<bool> watchEmailVerificationStatus() {
    return Stream<bool>.value(true);
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> resendEmailVerification(String email) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> confirmHasProfile() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> checkHasProfile() async {
    return switch (state) {
      FakeAuthState.authenticatedAsCustomer => const Right(true),
      FakeAuthState.authenticatedAsOwnerWithBusiness => const Right(true),
      FakeAuthState.authenticatedAsOwnerWithoutBusiness => const Right(true),
      FakeAuthState.expiredToken => Left(AuthenticationRequiredFailure()),
      FakeAuthState.unauthenticated => Left(AuthenticationRequiredFailure()),
    };
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    state = FakeAuthState.unauthenticated;
    onLogout?.call();
    return const Right(null);
  }
}
