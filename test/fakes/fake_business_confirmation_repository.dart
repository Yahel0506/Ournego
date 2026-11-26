import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/domain/repositories/business_confirmation_repository.dart';

/// In-memory stand-in for the server row (one answer per business).
class FakeBusinessConfirmationRepository
    implements BusinessConfirmationRepository {
  FakeBusinessConfirmationRepository({
    Map<String, BusinessConfirmationAnswer>? answers,
    this.failNextSubmit = false,
  }) : answers = answers ?? {};

  final Map<String, BusinessConfirmationAnswer> answers;
  bool failNextSubmit;
  int reads = 0;
  final List<BusinessConfirmationAnswer> submitted = [];

  @override
  Future<Either<Failure, BusinessConfirmationAnswer?>> getMyAnswer({
    required String businessId,
  }) async {
    reads++;
    return Right(answers[businessId]);
  }

  @override
  Future<Either<Failure, BusinessConfirmationAnswer>> submitAnswer({
    required String businessId,
    required BusinessConfirmationAnswer answer,
  }) async {
    if (failNextSubmit) {
      failNextSubmit = false;
      return Left(NetworkFailure());
    }
    submitted.add(answer);
    // The first answer wins, like the server.
    return Right(answers.putIfAbsent(businessId, () => answer));
  }
}
