import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';

abstract class ModerationRepository {
  /// Whether the signed-in account is on the reviewers allow-list. Only used
  /// to decide what to show: the server enforces every decision on its own.
  Future<Either<Failure, bool>> isReviewer();

  /// Listings in [status], oldest request first (pending) or by name.
  Future<Either<Failure, List<ReviewListing>>> getListings({
    required BusinessReviewStatus status,
  });

  /// History of a listing, newest first.
  Future<Either<Failure, List<ReviewLogEntry>>> getReviewLog({
    required String businessId,
  });

  /// Applies [decision]. Fails with [ModerationNotAuthorizedFailure] for any
  /// account that is not a reviewer, [ModerationReasonRequiredFailure] without
  /// a reason to reject or withdraw, and [ModerationStaleFailure] when the
  /// listing is no longer in the state the decision expects.
  Future<Either<Failure, void>> decide({
    required String businessId,
    required ReviewDecision decision,
    String? reason,
  });
}
