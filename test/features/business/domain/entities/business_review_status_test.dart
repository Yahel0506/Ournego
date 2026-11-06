import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/business/domain/entities/business_review_status.dart';

void main() {
  test('fromWire maps every database value', () {
    expect(
      BusinessReviewStatus.fromWire('pending'),
      BusinessReviewStatus.pending,
    );
    expect(
      BusinessReviewStatus.fromWire('approved'),
      BusinessReviewStatus.approved,
    );
    expect(
      BusinessReviewStatus.fromWire('rejected'),
      BusinessReviewStatus.rejected,
    );
    expect(
      BusinessReviewStatus.fromWire('withdrawn'),
      BusinessReviewStatus.withdrawn,
    );
  });

  test('unknown or missing values are never shown as published', () {
    expect(BusinessReviewStatus.fromWire(null), BusinessReviewStatus.pending);
    expect(BusinessReviewStatus.fromWire('oops'), BusinessReviewStatus.pending);
  });

  test('only rejected and withdrawn listings can request a review', () {
    expect(BusinessReviewStatus.values.where((s) => s.canRequestReview), [
      BusinessReviewStatus.rejected,
      BusinessReviewStatus.withdrawn,
    ]);
  });
}
