import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/data/datasources/local_auth_selection_datasource.dart';
import 'package:ournego/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/entities/auth_selection.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalAuthSelectionDatasource authSelectionDatasource;
  final SupabaseAuthDatasource authDatasource;

  AuthRepositoryImpl({
    required this.authSelectionDatasource,
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

      AppUser user = AppUser(uid: rawUser.id, email: rawUser.email);

      return Right(user);
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return Left(EmailAlreadyInUseFailure());
      }
      debugPrint(e.message);
      return Left(ServerFailure());
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
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

      AppUser user = AppUser(uid: rawUser.id, email: rawUser.email);

      final bool hasProfile = await authDatasource.checkHasProfile();

      if (!hasProfile) {
        debugPrint('No tiene perfil');
        return Left(UserProfileNotFound());
      }

      debugPrint('Login exitoso para usuario: ${user.email}');
      return Right(user);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return Left(InvalidCredentialsFailure());
      }
      debugPrint(e.message);
      return Left(ServerFailure());
    } on Exception catch (e) {
      debugPrint('Exception en logInWithEmail: ${e.toString()}');
      return Left(ServerFailure());
    } catch (e) {
      debugPrint('Error desconocido en logInWithEmail: ${e.toString()}');
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      return Right(await authDatasource.signInWithGoogle());
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateProfilePicture(
    File profilePicture,
  ) async {
    try {
      return Right(await authDatasource.updateProfilePicture(profilePicture));
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUserName(String name) async {
    try {
      return Right(await authDatasource.updateUserName(name));
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Stream<AppUser> getProfile({String? userId}) {
    if (userId != null) {
      final user = authDatasource.getProfile(id: userId).map((data) {
        return data.map((user) {
          return AppUser(
            uid: user['id'],
            name: user['name'],
            profilePicture: user['avatar_url'],
          );
        }).toList()[0];
      });
      return user;
    } else {
      final user = authDatasource.getProfile().map((data) {
        return data.map((user) {
          return AppUser(
            uid: user['id'],
            name: user['name'],
            profilePicture: user['avatar_url'],
          );
        }).toList()[0];
      });
      return user;
    }
  }

  @override
  Future<Either<Failure, void>> confirmHasProfile() async {
    try {
      return Right(await authDatasource.confirmHasProfile());
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkHasProfile() async {
    try {
      return Right(await authDatasource.checkHasProfile());
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      return Right(await authDatasource.logOut());
    } on Exception catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure());
    } catch (_) {
      return Left(ServerFailure());
    }
  }
}
