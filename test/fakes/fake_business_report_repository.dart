import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';
import 'package:ournego/features/business/domain/repositories/business_report_repository.dart';

/// Records the reports a widget sends, or fails them with [failure].
class FakeBusinessReportRepository implements BusinessReportRepository {
  FakeBusinessReportRepository({this.failure});

  Failure? failure;
  final List<({String businessId, BusinessReportReason reason, String? note})>
  submitted = [];

  @override
  Future<Either<Failure, Unit>> submitReport({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  }) async {
    final error = failure;
    if (error != null) return Left(error);
    submitted.add((businessId: businessId, reason: reason, note: note));
    return const Right(unit);
  }
}
