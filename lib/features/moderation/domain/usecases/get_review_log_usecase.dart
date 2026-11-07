import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

class GetReviewLogUsecase {
  final ModerationRepository repository;

  GetReviewLogUsecase({required this.repository});

  Future<Either<Failure, List<ReviewLogEntry>>> call({
    required String businessId,
  }) => repository.getReviewLog(businessId: businessId);
}
