import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/network/network_error_classifier.dart';
import 'package:ournego/features/business/data/datasources/business_report_supabase_datasource.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';
import 'package:ournego/features/business/domain/repositories/business_report_repository.dart';

class BusinessReportRepositoryImpl implements BusinessReportRepository {
  final BusinessReportSupabaseDatasource datasource;

  BusinessReportRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, Unit>> submitReport({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  }) async {
    try {
      await datasource.submitReport(
        businessId: businessId,
        reason: reason,
        note: note,
      );
      return const Right(unit);
    } on BusinessReportRuleException catch (e) {
      return Left(switch (e.code) {
        'report_limit_reached' => BusinessReportLimitFailure(),
        'business_not_found' => BusinessReportUnavailableFailure(),
        'not_authenticated' => SessionExpiredFailure(),
        _ => ServerFailure(),
      });
    } catch (e) {
      if (isSessionExpiredError(e)) return Left(SessionExpiredFailure());
      if (isNetworkError(e)) return Left(NetworkFailure());
      return Left(ServerFailure());
    }
  }
}
