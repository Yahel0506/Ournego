import 'package:ournego/features/business/domain/entities/business_review_status.dart';

/// A listing as the reviewer sees it in the queue.
class ReviewListing {
  final String id;
  final String name;
  final String description;
  final int category;
  final String address;
  final String? phoneNumber;
  final List<String> images;
  final BusinessReviewStatus status;

  /// When the owner last sent the listing to review.
  final DateTime? submittedAt;

  /// When a reviewer last decided on the listing.
  final DateTime? reviewedAt;

  /// Reason of the last rejection or withdrawal.
  final String? reason;

  const ReviewListing({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phoneNumber,
    required this.images,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.reason,
  });
}
