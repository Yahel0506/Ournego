/// Where an owned listing stands in the publication review.
///
/// Mirrors `businesses.status`. Only [approved] listings are public.
enum BusinessReviewStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  /// Parses the database value. Unknown or missing values are treated as
  /// [pending] so the owner never sees a listing as published by mistake.
  static BusinessReviewStatus fromWire(String? value) {
    switch (value) {
      case 'approved':
        return BusinessReviewStatus.approved;
      case 'rejected':
        return BusinessReviewStatus.rejected;
      case 'withdrawn':
        return BusinessReviewStatus.withdrawn;
      case 'pending':
      default:
        return BusinessReviewStatus.pending;
    }
  }

  /// The owner may ask for a (new) review only after a rejection or withdrawal.
  bool get canRequestReview =>
      this == BusinessReviewStatus.rejected ||
      this == BusinessReviewStatus.withdrawn;
}
