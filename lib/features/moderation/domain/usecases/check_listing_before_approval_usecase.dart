import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/listing_check.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/domain/listing_checker.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

/// Checks a pending listing against the pilot contract and against the pending
/// and published catalog, so a reviewer sees invalid content and likely
/// duplicates before approving.
class CheckListingBeforeApprovalUsecase {
  final ModerationRepository repository;

  CheckListingBeforeApprovalUsecase({required this.repository});

  Future<Either<Failure, ListingReport>> call({
    required ReviewListing listing,
  }) async {
    final pending = await repository.getListings(
      status: BusinessReviewStatus.pending,
    );
    final approved = await repository.getListings(
      status: BusinessReviewStatus.approved,
    );
    // Without the catalog a duplicate could slip through: fail instead of
    // reporting a clean result.
    final failure =
        pending.fold<Failure?>((f) => f, (_) => null) ??
        approved.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return Left(failure);

    final others = [
      ...pending.getOrElse(() => const []),
      ...approved.getOrElse(() => const []),
    ];
    return Right(checkListing(listing, others: others));
  }
}
