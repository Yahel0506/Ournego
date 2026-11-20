import 'package:ournego/features/business/domain/entities/business_review_status.dart';

/// What a reviewer can do with a listing.
enum ReviewDecision {
  approve,
  reject,
  withdraw,
  restore,
  withdrawUnderReview;

  /// The status the listing must be in for this decision to make sense. A
  /// stale tap (someone else decided first) fails instead of overwriting it.
  BusinessReviewStatus get requiredStatus => switch (this) {
    ReviewDecision.approve ||
    ReviewDecision.reject => BusinessReviewStatus.pending,
    ReviewDecision.withdraw => BusinessReviewStatus.approved,
    ReviewDecision.restore ||
    ReviewDecision.withdrawUnderReview => BusinessReviewStatus.underReview,
  };

  BusinessReviewStatus get resultingStatus {
    switch (this) {
      case ReviewDecision.approve:
        return BusinessReviewStatus.approved;
      case ReviewDecision.reject:
        return BusinessReviewStatus.rejected;
      case ReviewDecision.withdraw:
      case ReviewDecision.withdrawUnderReview:
        return BusinessReviewStatus.withdrawn;
      case ReviewDecision.restore:
        return BusinessReviewStatus.approved;
    }
  }

  /// Rejecting or withdrawing is explained to the owner, so it needs a reason.
  bool get requiresReason => switch (this) {
    ReviewDecision.reject ||
    ReviewDecision.withdraw ||
    ReviewDecision.withdrawUnderReview => true,
    ReviewDecision.approve || ReviewDecision.restore => false,
  };
}
