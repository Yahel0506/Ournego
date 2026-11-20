import 'package:ournego/features/business/domain/entities/business_submission_result.dart';

class BusinessSubmissionResultModel extends BusinessSubmissionResult {
  const BusinessSubmissionResultModel({
    required super.businessId,
    required super.status,
    super.reviewPendingReason,
  });

  factory BusinessSubmissionResultModel.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'approved' => BusinessSubmissionStatus.approved,
      _ => BusinessSubmissionStatus.pending,
    };
    final reason = json['review_pending_reason'];
    return BusinessSubmissionResultModel(
      businessId: json['business_id'] as String,
      status: status,
      reviewPendingReason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : null,
    );
  }
}
