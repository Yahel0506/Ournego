import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';

abstract class BusinessReportRepository {
  /// Sends a report of [businessId] through the server rule.
  ///
  /// A user keeps one open report per business: repeating the call succeeds
  /// without creating a second one. The result never says whether the report
  /// counted or hid the listing.
  Future<Either<Failure, Unit>> submitReport({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  });
}
