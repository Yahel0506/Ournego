import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';
import 'package:ournego/features/moderation/presentation/pages/moderation_screen.dart';
import 'package:ournego/features/moderation/presentation/providers/moderation_providers.dart';

import '../../../fakes/fake_moderation_repository.dart';

void main() {
  Future<void> pump(WidgetTester tester, FakeModerationRepository repo) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moderationRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('reviewer-1'),
        ],
        child: MaterialApp(
          theme: OurnegoTheme.light,
          // The animated background never settles otherwise.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const ModerationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an account that is not a reviewer sees no queue', (
    tester,
  ) async {
    final repo = FakeModerationRepository(
      reviewer: false,
      pending: [fakeReviewListing('a')],
    );
    await pump(tester, repo);

    expect(find.byKey(const Key('moderationNoAccess')), findsOneWidget);
    expect(find.byKey(const Key('reviewListingCard_a')), findsNothing);
    expect(find.byKey(const Key('approveButton_a')), findsNothing);
  });

  testWidgets('the reviewer sees pending requests oldest first with actions', (
    tester,
  ) async {
    final repo = FakeModerationRepository(
      pending: [fakeReviewListing('a'), fakeReviewListing('b')],
    );
    await pump(tester, repo);

    expect(find.byKey(const Key('reviewListingCard_a')), findsOneWidget);
    expect(find.byKey(const Key('reviewListingCard_b')), findsOneWidget);
    expect(find.byKey(const Key('approveButton_a')), findsOneWidget);
    expect(find.byKey(const Key('rejectButton_a')), findsOneWidget);
    expect(find.byKey(const Key('withdrawButton_a')), findsNothing);
  });

  testWidgets('shows an empty state', (tester) async {
    await pump(tester, FakeModerationRepository());
    expect(find.byKey(const Key('moderationEmpty')), findsOneWidget);
  });

  testWidgets('approving asks for confirmation and removes it from the queue', (
    tester,
  ) async {
    final repo = FakeModerationRepository(pending: [fakeReviewListing('a')]);
    await pump(tester, repo);

    await tester.tap(find.byKey(const Key('approveButton_a')));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty, reason: 'nothing happens before confirming');

    await tester.tap(find.byKey(const Key('confirmApproveButton')));
    await tester.pumpAndSettle();

    expect(repo.calls.single.decision, ReviewDecision.approve);
    expect(repo.calls.single.businessId, 'a');
    expect(find.byKey(const Key('reviewListingCard_a')), findsNothing);
    expect(find.byKey(const Key('moderationEmpty')), findsOneWidget);
  });

  testWidgets('invalid content blocks approving and shows why', (tester) async {
    final repo = FakeModerationRepository(
      pending: [fakeReviewListing('a', images: const [], latitude: null)],
    );
    await pump(tester, repo);

    await tester.tap(find.byKey(const Key('approveButton_a')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('listingReport')), findsOneWidget);
    expect(find.text('• No tiene ninguna imagen.'), findsOneWidget);
    expect(find.byKey(const Key('confirmApproveButton')), findsNothing);

    await tester.tap(find.byKey(const Key('confirmReportButton')));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(find.byKey(const Key('reviewListingCard_a')), findsOneWidget);
  });

  testWidgets('a possible duplicate needs an explicit "approve anyway"', (
    tester,
  ) async {
    final repo = FakeModerationRepository(
      pending: [fakeReviewListing('a', name: 'Café Luna')],
      approved: [
        fakeReviewListing(
          'p',
          name: 'Café Luna',
          status: BusinessReviewStatus.approved,
        ),
      ],
    );
    await pump(tester, repo);

    await tester.tap(find.byKey(const Key('approveButton_a')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Posibles duplicados'), findsOneWidget);
    expect(find.textContaining('ya publicada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmReportButton')));
    await tester.pumpAndSettle();
    expect(repo.calls.single.decision, ReviewDecision.approve);
  });

  testWidgets('the card shows the opening hours', (tester) async {
    final repo = FakeModerationRepository(pending: [fakeReviewListing('a')]);
    await pump(tester, repo);
    expect(find.text('Lun 09:00-18:00'), findsOneWidget);
  });

  testWidgets('rejecting needs a reason', (tester) async {
    final repo = FakeModerationRepository(pending: [fakeReviewListing('a')]);
    await pump(tester, repo);

    await tester.tap(find.byKey(const Key('rejectButton_a')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirmReasonButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reviewReasonError')), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('reviewReasonField')),
      '  Falta la dirección ',
    );
    await tester.tap(find.byKey(const Key('confirmReasonButton')));
    await tester.pumpAndSettle();

    expect(repo.calls.single.decision, ReviewDecision.reject);
    expect(repo.calls.single.reason, 'Falta la dirección');
    expect(find.byKey(const Key('reviewListingCard_a')), findsNothing);
  });

  testWidgets('published listings can be withdrawn with a reason', (
    tester,
  ) async {
    final repo = FakeModerationRepository(
      approved: [fakeReviewListing('p', status: BusinessReviewStatus.approved)],
    );
    await pump(tester, repo);

    await tester.tap(find.byKey(const Key('moderationTabPublished')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approveButton_p')), findsNothing);

    await tester.tap(find.byKey(const Key('withdrawButton_p')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reviewReasonField')), 'Cerró');
    await tester.tap(find.byKey(const Key('confirmReasonButton')));
    await tester.pumpAndSettle();

    expect(repo.calls.single.decision, ReviewDecision.withdraw);
    expect(repo.calls.single.reason, 'Cerró');
    expect(find.byKey(const Key('reviewListingCard_p')), findsNothing);
  });

  testWidgets(
    'the server refusing the decision keeps the listing and says so',
    (tester) async {
      final repo = FakeModerationRepository(
        pending: [fakeReviewListing('a')],
        decideFailure: ModerationNotAuthorizedFailure(),
      );
      await pump(tester, repo);

      await tester.tap(find.byKey(const Key('approveButton_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmApproveButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Tu cuenta no puede resolver solicitudes.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reviewListingCard_a')), findsOneWidget);
    },
  );

  testWidgets('the history shows who, when and why', (tester) async {
    final repo = FakeModerationRepository(
      pending: [fakeReviewListing('a')],
      log: [
        ReviewLogEntry(
          id: 2,
          from: BusinessReviewStatus.pending,
          to: BusinessReviewStatus.rejected,
          actorRole: ReviewActorRole.reviewer,
          actorId: 'u2',
          reason: 'Falta la dirección',
          createdAt: DateTime(2026, 11, 4, 10, 30),
        ),
        ReviewLogEntry(
          id: 1,
          from: null,
          to: BusinessReviewStatus.pending,
          actorRole: ReviewActorRole.owner,
          actorId: 'u1',
          reason: null,
          createdAt: DateTime(2026, 11, 3, 9, 0),
        ),
      ],
    );
    await pump(tester, repo);

    await tester.tap(find.byKey(const Key('historyButton_a')));
    await tester.pumpAndSettle();

    expect(find.text('Rechazada'), findsOneWidget);
    expect(find.text('Revisión · 04/11/2026 10:30'), findsOneWidget);
    expect(find.text('Motivo: Falta la dirección'), findsOneWidget);
    expect(find.text('Solicitud de alta enviada'), findsOneWidget);
  });
}
