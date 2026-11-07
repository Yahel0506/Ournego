import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

class CheckIsReviewerUsecase {
  final ModerationRepository repository;

  CheckIsReviewerUsecase({required this.repository});

  Future<Either<Failure, bool>> call() => repository.isReviewer();
}
