import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/domain/repositories/business_confirmation_repository.dart';

class GetMyBusinessConfirmationUsecase {
  final BusinessConfirmationRepository repository;

  GetMyBusinessConfirmationUsecase({required this.repository});

  Future<Either<Failure, BusinessConfirmationAnswer?>> call({
    required String businessId,
  }) {
    return repository.getMyAnswer(businessId: businessId);
  }
}
