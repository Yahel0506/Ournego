import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

class DecideBusinessReviewUsecase {
  final ModerationRepository repository;

  DecideBusinessReviewUsecase({required this.repository});

  /// Rejecting or withdrawing needs a non-blank reason; it is trimmed here and
  /// checked again by the server.
  Future<Either<Failure, void>> call({
    required String businessId,
    required ReviewDecision decision,
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    if (decision.requiresReason && (trimmed == null || trimmed.isEmpty)) {
      return Left(ModerationReasonRequiredFailure());
    }
    return repository.decide(
      businessId: businessId,
      decision: decision,
      reason: decision.requiresReason ? trimmed : null,
    );
  }
}
