import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';
import 'package:ournego/features/business/domain/repositories/business_report_repository.dart';

class SubmitBusinessReportUsecase {
  final BusinessReportRepository repository;

  SubmitBusinessReportUsecase({required this.repository});

  Future<Either<Failure, Unit>> call({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  }) {
    final trimmed = note?.trim();
    return repository.submitReport(
      businessId: businessId,
      reason: reason,
      note: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }
}
