import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

/// Cancels the signed-in user's scheduled account deletion (D10 of the
/// OUR-142 plan). Resolves to `true` when something was cancelled.
class CancelMyDeletionUsecase {
  final AuthRepository repository;

  CancelMyDeletionUsecase({required this.repository});

  Future<Either<Failure, bool>> call() {
    return repository.cancelMyDeletion();
  }
}
