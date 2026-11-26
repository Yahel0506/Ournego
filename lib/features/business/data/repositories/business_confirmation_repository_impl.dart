import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/network/network_error_classifier.dart';
import 'package:ournego/features/business/data/datasources/business_confirmation_supabase_datasource.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/domain/repositories/business_confirmation_repository.dart';

class BusinessConfirmationRepositoryImpl
    implements BusinessConfirmationRepository {
  final BusinessConfirmationSupabaseDatasource datasource;

  BusinessConfirmationRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, BusinessConfirmationAnswer?>> getMyAnswer({
    required String businessId,
  }) async {
    try {
      return Right(await datasource.getMyAnswer(businessId: businessId));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, BusinessConfirmationAnswer>> submitAnswer({
    required String businessId,
    required BusinessConfirmationAnswer answer,
  }) async {
    try {
      return Right(
        await datasource.submitAnswer(businessId: businessId, answer: answer),
      );
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  Failure _toFailure(Object error) {
    if (isSessionExpiredError(error)) return SessionExpiredFailure();
    if (isNetworkError(error)) return NetworkFailure();
    return ServerFailure();
  }
}
