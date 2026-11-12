import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/listing_check.dart';
import 'package:ournego/features/moderation/domain/listing_checker.dart';
import 'package:ournego/features/moderation/domain/usecases/check_listing_before_approval_usecase.dart';

import '../../../fakes/fake_moderation_repository.dart';

void main() {
  group('checkListing - content', () {
    test('a complete listing has no issues and can be approved', () {
      final report = checkListing(fakeReviewListing('a'));
      expect(report.issues, isEmpty);
      expect(report.duplicates, isEmpty);
      expect(report.canApprove, isTrue);
      expect(report.needsAttention, isFalse);
    });

    test('flags every missing or invalid required field as blocking', () {
      final report = checkListing(
        fakeReviewListing(
          'a',
          name: ' x ',
          address: '  ',
          images: const [],
          latitude: null,
          phoneNumber: '12',
          hours: const [
            AppSchedule(dayOfWeek: 1, openMinutes: 600, closeMinutes: 600),
          ],
        ),
      );
      expect(
        report.blocking,
        containsAll([
          ListingIssue.nameTooShort,
          ListingIssue.missingAddress,
          ListingIssue.missingImages,
          ListingIssue.invalidCoordinates,
          ListingIssue.invalidPhone,
          ListingIssue.invalidHours,
        ]),
      );
      expect(report.canApprove, isFalse);
    });

    test('coordinates (0, 0) or out of range are invalid', () {
      for (final c in [(0.0, 0.0), (91.0, 0.0), (0.0, 181.0)]) {
        final report = checkListing(
          fakeReviewListing('a', latitude: c.$1, longitude: c.$2),
        );
        expect(report.blocking, contains(ListingIssue.invalidCoordinates));
      }
    });

    test('missing phone, hours or description only warn', () {
      final report = checkListing(
        fakeReviewListing('a', withoutPhone: true, hours: const []),
      );
      expect(report.warnings, [
        ListingIssue.missingPhone,
        ListingIssue.missingHours,
      ]);
      expect(report.canApprove, isTrue);
      expect(report.needsAttention, isTrue);
    });

    test('a closing time after midnight is a valid schedule', () {
      final report = checkListing(
        fakeReviewListing(
          'a',
          hours: const [
            AppSchedule(dayOfWeek: 4, openMinutes: 1200, closeMinutes: 120),
          ],
        ),
      );
      expect(report.issues, isEmpty);
    });
  });

  group('checkListing - duplicates', () {
    test('same name close by is a duplicate, far away is not', () {
      final listing = fakeReviewListing('a', name: 'Café Luna');
      final near = fakeReviewListing(
        'b',
        name: 'cafe  luna!',
        latitude: 40.0005,
        status: BusinessReviewStatus.approved,
      );
      final far = fakeReviewListing('c', name: 'Café Luna', latitude: 41.0);

      final report = checkListing(listing, others: [near, far]);
      expect(report.duplicates.map((d) => d.listing.id), ['b']);
      expect(report.duplicates.single.reason, DuplicateReason.sameNameAndPlace);
      expect(report.canApprove, isTrue);
      expect(report.needsAttention, isTrue);
    });

    test('same phone, even formatted differently, is a duplicate', () {
      final listing = fakeReviewListing('a', phoneNumber: '+34 600-111-222');
      final other = fakeReviewListing(
        'b',
        name: 'Otro',
        phoneNumber: '600111222',
        latitude: 10,
      );
      final report = checkListing(listing, others: [other]);
      expect(report.duplicates.single.reason, DuplicateReason.samePhone);
    });

    test('same address is a duplicate; the listing never matches itself', () {
      final listing = fakeReviewListing('a', address: 'Calle Mayor 1');
      final other = fakeReviewListing(
        'b',
        name: 'Otro',
        address: 'calle mayor, 1',
        latitude: 10,
      );
      final report = checkListing(listing, others: [listing, other]);
      expect(report.duplicates.single.reason, DuplicateReason.sameAddress);
    });
  });

  group('CheckListingBeforeApprovalUsecase', () {
    test('compares against pending and published listings', () async {
      final repo = FakeModerationRepository(
        pending: [
          fakeReviewListing('a', name: 'Panadería Sol'),
          fakeReviewListing('b', name: 'Panadería Sol'),
        ],
        approved: [
          fakeReviewListing(
            'c',
            name: 'Panadería Sol',
            status: BusinessReviewStatus.approved,
          ),
        ],
      );
      final result = await CheckListingBeforeApprovalUsecase(repository: repo)(
        listing: repo.pending.first,
      );
      final report = result.getOrElse(() => throw StateError('failed'));
      expect(report.duplicates.map((d) => d.listing.id), ['b', 'c']);
    });
  });
}
