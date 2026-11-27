import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/business/domain/entities/business_report_reason.dart';
import 'package:ournego/features/business/domain/usecases/submit_business_report_usecase.dart';

import '../../../../fakes/fake_business_report_repository.dart';

void main() {
  test('trims the note and drops a blank one', () async {
    final repository = FakeBusinessReportRepository();
    final usecase = SubmitBusinessReportUsecase(repository: repository);

    await usecase(
      businessId: 'b1',
      reason: BusinessReportReason.other,
      note: '  ya no abre  ',
    );
    await usecase(
      businessId: 'b1',
      reason: BusinessReportReason.closed,
      note: '   ',
    );

    expect(repository.submitted[0].note, 'ya no abre');
    expect(repository.submitted[1].note, isNull);
  });
}
