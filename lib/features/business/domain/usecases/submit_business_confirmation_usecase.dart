import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/domain/repositories/business_confirmation_repository.dart';

class SubmitBusinessConfirmationUsecase {
  final BusinessConfirmationRepository repository;

  SubmitBusinessConfirmationUsecase({required this.repository});

  Future<Either<Failure, BusinessConfirmationAnswer>> call({
    required String businessId,
    required BusinessConfirmationAnswer answer,
  }) {
    return repository.submitAnswer(businessId: businessId, answer: answer);
  }
}
