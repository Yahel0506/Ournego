import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';

abstract class BusinessConfirmationRepository {
  /// The signed-in user's own answer for [businessId], or `null` when they
  /// have not answered yet. The server row is the source of truth.
  Future<Either<Failure, BusinessConfirmationAnswer?>> getMyAnswer({
    required String businessId,
  });

  /// Records [answer] through the server rule. The first answer wins: a
  /// repeated call returns the stored answer instead of overwriting it.
  Future<Either<Failure, BusinessConfirmationAnswer>> submitAnswer({
    required String businessId,
    required BusinessConfirmationAnswer answer,
  });
}
