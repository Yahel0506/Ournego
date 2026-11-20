import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/features/business/data/models/business_submission_result_model.dart';
import 'package:ournego/features/business/domain/entities/business_submission_result.dart';

void main() {
  test('decodes an approved server result', () {
    final result = BusinessSubmissionResultModel.fromJson({
      'business_id': 'listing-id',
      'status': 'approved',
      'review_pending_reason': null,
    });

    expect(result.businessId, 'listing-id');
    expect(result.status, BusinessSubmissionStatus.approved);
    expect(result.reviewPendingReason, isNull);
  });

  test('decodes a pending server result and its reason', () {
    final result = BusinessSubmissionResultModel.fromJson({
      'business_id': 'listing-id',
      'status': 'pending',
      'review_pending_reason': 'possible_duplicate',
    });

    expect(result.status, BusinessSubmissionStatus.pending);
    expect(result.reviewPendingReason, 'possible_duplicate');
  });
}
