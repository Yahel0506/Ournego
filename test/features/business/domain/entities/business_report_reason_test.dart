import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/business/domain/entities/business_report_reason.dart';

void main() {
  test('wire values match the database check constraint', () {
    expect(BusinessReportReason.values.map((r) => r.wire), [
      'no_exists',
      'closed',
      'incorrect_info',
      'inappropriate',
      'duplicate',
      'other',
    ]);
  });

  test('tryFromWire parses known values and ignores unknown ones', () {
    for (final reason in BusinessReportReason.values) {
      expect(BusinessReportReason.tryFromWire(reason.wire), reason);
    }
    expect(BusinessReportReason.tryFromWire('spam'), isNull);
    expect(BusinessReportReason.tryFromWire(null), isNull);
  });

  test('only "other" requires a note', () {
    expect(BusinessReportReason.values.where((r) => r.requiresNote), [
      BusinessReportReason.other,
    ]);
  });
}
