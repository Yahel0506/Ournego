enum BusinessSubmissionStatus { approved, pending }

class BusinessSubmissionResult {
  final String businessId;
  final BusinessSubmissionStatus status;
  final String? reviewPendingReason;

  const BusinessSubmissionResult({
    required this.businessId,
    required this.status,
    this.reviewPendingReason,
  });
}
