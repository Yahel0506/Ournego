import 'package:ournego/features/business/domain/entities/business_review_status.dart';

/// What a reviewer can do with a listing.
enum ReviewDecision {
  approve,
  reject,
  withdraw;

  /// The status the listing must be in for this decision to make sense. A
  /// stale tap (someone else decided first) fails instead of overwriting it.
  BusinessReviewStatus get requiredStatus => this == ReviewDecision.withdraw
      ? BusinessReviewStatus.approved
      : BusinessReviewStatus.pending;

  BusinessReviewStatus get resultingStatus {
    switch (this) {
      case ReviewDecision.approve:
        return BusinessReviewStatus.approved;
      case ReviewDecision.reject:
        return BusinessReviewStatus.rejected;
      case ReviewDecision.withdraw:
        return BusinessReviewStatus.withdrawn;
    }
  }

  /// Rejecting or withdrawing is explained to the owner, so it needs a reason.
  bool get requiresReason => this != ReviewDecision.approve;
}
