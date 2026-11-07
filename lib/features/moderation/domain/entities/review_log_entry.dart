import 'package:ournego/features/business/domain/entities/business_review_status.dart';

/// Who made a status change.
enum ReviewActorRole {
  reviewer,
  owner,
  system;

  static ReviewActorRole fromWire(String? value) {
    switch (value) {
      case 'reviewer':
        return ReviewActorRole.reviewer;
      case 'owner':
        return ReviewActorRole.owner;
      case 'system':
      default:
        return ReviewActorRole.system;
    }
  }
}

/// One row of the append-only history of a listing (`business_review_log`).
class ReviewLogEntry {
  final int id;
  final BusinessReviewStatus? from;
  final BusinessReviewStatus to;
  final ReviewActorRole actorRole;

  /// User that made the change; null for the service role or deleted accounts.
  final String? actorId;
  final String? reason;
  final DateTime createdAt;

  const ReviewLogEntry({
    required this.id,
    required this.from,
    required this.to,
    required this.actorRole,
    required this.actorId,
    required this.reason,
    required this.createdAt,
  });
}
