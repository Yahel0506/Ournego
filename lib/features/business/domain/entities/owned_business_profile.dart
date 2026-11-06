import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';

class OwnedBusinessProfile {
  final String id;
  final String name;
  final String description;
  final int category;
  final String address;
  final String? phoneNumber;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<AppSchedule> hours;
  final BusinessReviewStatus reviewStatus;

  /// Why a reviewer rejected the listing; only set while [reviewStatus] is
  /// [BusinessReviewStatus.rejected].
  final String? rejectionReason;

  /// When the listing was last sent to review.
  final DateTime? submittedAt;

  /// When a reviewer last decided on the listing.
  final DateTime? reviewedAt;

  const OwnedBusinessProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.hours,
    this.reviewStatus = BusinessReviewStatus.approved,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });
}
