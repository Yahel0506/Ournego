import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

class GetReviewListingsUsecase {
  final ModerationRepository repository;

  GetReviewListingsUsecase({required this.repository});

  Future<Either<Failure, List<ReviewListing>>> call({
    required BusinessReviewStatus status,
  }) => repository.getListings(status: status);
}
