import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/usecases/decide_business_review_usecase.dart';

import '../../../fakes/fake_moderation_repository.dart';

void main() {
  group('ReviewDecision', () {
    test('approve and reject start from pending, withdraw from approved', () {
      expect(
        ReviewDecision.approve.requiredStatus,
        BusinessReviewStatus.pending,
      );
      expect(
        ReviewDecision.reject.requiredStatus,
        BusinessReviewStatus.pending,
      );
      expect(
        ReviewDecision.withdraw.requiredStatus,
        BusinessReviewStatus.approved,
      );
    });

    test(
      'each decision leads to its status and only approve needs no reason',
      () {
        expect(
          ReviewDecision.approve.resultingStatus,
          BusinessReviewStatus.approved,
        );
        expect(
          ReviewDecision.reject.resultingStatus,
          BusinessReviewStatus.rejected,
        );
        expect(
          ReviewDecision.withdraw.resultingStatus,
          BusinessReviewStatus.withdrawn,
        );
        expect(ReviewDecision.approve.requiresReason, isFalse);
        expect(ReviewDecision.reject.requiresReason, isTrue);
        expect(ReviewDecision.withdraw.requiresReason, isTrue);
      },
    );

    test('wire values match the database enum', () {
      expect(BusinessReviewStatus.values.map((s) => s.wire), [
        'pending',
        'approved',
        'rejected',
        'withdrawn',
      ]);
      for (final status in BusinessReviewStatus.values) {
        expect(BusinessReviewStatus.fromWire(status.wire), status);
      }
    });
  });

  group('DecideBusinessReviewUsecase', () {
    late FakeModerationRepository repository;
    late DecideBusinessReviewUsecase usecase;

    setUp(() {
      repository = FakeModerationRepository(
        pending: [fakeReviewListing('a')],
        approved: [
          fakeReviewListing('b', status: BusinessReviewStatus.approved),
        ],
      );
      usecase = DecideBusinessReviewUsecase(repository: repository);
    });

    test(
      'rejecting without a reason fails before reaching the server',
      () async {
        for (final reason in <String?>[null, '', '   ']) {
          final result = await usecase(
            businessId: 'a',
            decision: ReviewDecision.reject,
            reason: reason,
          );
          expect(
            result.fold((f) => f, (_) => null),
            isA<ModerationReasonRequiredFailure>(),
          );
        }
        expect(repository.calls, isEmpty);
      },
    );

    test('withdrawing without a reason fails', () async {
      final result = await usecase(
        businessId: 'b',
        decision: ReviewDecision.withdraw,
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    });

    test('the reason is trimmed and approve sends none', () async {
      await usecase(
        businessId: 'a',
        decision: ReviewDecision.reject,
        reason: '  Foto borrosa ',
      );
      expect(repository.calls.single.reason, 'Foto borrosa');

      await usecase(
        businessId: 'b',
        decision: ReviewDecision.withdraw,
        reason: 'Cerró',
      );
      expect(repository.calls.last.reason, 'Cerró');

      final approve = FakeModerationRepository(
        pending: [fakeReviewListing('c')],
      );
      await DecideBusinessReviewUsecase(repository: approve)(
        businessId: 'c',
        decision: ReviewDecision.approve,
        reason: 'ignored',
      );
      expect(approve.calls.single.reason, isNull);
    });

    test('a listing that already moved on is reported as stale', () async {
      final result = await usecase(
        businessId: 'missing',
        decision: ReviewDecision.approve,
      );
      expect(result.fold((f) => f, (_) => null), isA<ModerationStaleFailure>());
    });
  });
}
