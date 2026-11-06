import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class SubmitBusinessForReviewUsecase {
  final BusinessRepository repository;

  SubmitBusinessForReviewUsecase({required this.repository});

  Future<Either<Failure, void>> call({required String businessId}) async {
    return repository.submitBusinessForReview(businessId: businessId);
  }
}
