import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/data/datasources/supabase_moderation_datasource.dart';
import 'package:ournego/features/moderation/data/errors/moderation_exceptions.dart';
import 'package:ournego/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';

class _ThrowingDatasource extends SupabaseModerationDatasource {
  _ThrowingDatasource(this.error);

  final Object error;

  @override
  Future<void> decide({
    required String businessId,
    required ReviewDecision decision,
    String? reason,
  }) async => throw error;

  @override
  Future<bool> isReviewer() async => throw error;
}

void main() {
  Future<Failure?> decideWith(Object error) async {
    final repository = ModerationRepositoryImpl(
      datasource: _ThrowingDatasource(error),
    );
    final result = await repository.decide(
      businessId: 'a',
      decision: ReviewDecision.approve,
    );
    return result.fold((f) => f, (_) => null);
  }

  test('maps server rejections to moderation failures', () async {
    expect(
      await decideWith(ModerationNotAuthorizedException()),
      isA<ModerationNotAuthorizedFailure>(),
    );
    expect(
      await decideWith(ModerationReasonRequiredException()),
      isA<ModerationReasonRequiredFailure>(),
    );
    expect(
      await decideWith(ModerationStaleException()),
      isA<ModerationStaleFailure>(),
    );
    expect(await decideWith(StateError('boom')), isA<ServerFailure>());
  });

  test('a failed reviewer check is a failure, never "reviewer"', () async {
    final repository = ModerationRepositoryImpl(
      datasource: _ThrowingDatasource(StateError('boom')),
    );
    final result = await repository.isReviewer();
    expect(result.isLeft(), isTrue);
  });

  test('parses a queue row', () {
    final listing = ModerationRepositoryImpl.parseListing({
      'business_id': 'b1',
      'name': 'Cafetería',
      'description': 'Café',
      'type': 3,
      'address': 'Calle 1',
      'phone_number': ' ',
      'images': ['https://x/1.png', 7],
      'status': 'pending',
      'submitted_at': '2026-11-03T10:00:00Z',
      'reviewed_at': null,
      'rejection_reason': '  Foto borrosa ',
    });
    expect(listing.id, 'b1');
    expect(listing.category, 3);
    expect(listing.phoneNumber, isNull);
    expect(listing.images, ['https://x/1.png']);
    expect(listing.status, BusinessReviewStatus.pending);
    expect(listing.submittedAt, isNotNull);
    expect(listing.reason, 'Foto borrosa');
  });

  test('parses coordinates and hours (DB day 1 = Monday)', () {
    final listing = ModerationRepositoryImpl.parseListing({
      'business_id': 'b1',
      'latitude': 40,
      'longitude': -3.5,
      'hours': [
        {
          'day_of_week': 1,
          'opening_time': '09:00:00',
          'closing_time': '18:30:00',
        },
        {'day_of_week': 7, 'opening_time': null, 'closing_time': '10:00:00'},
      ],
      'status': 'pending',
    });
    expect(listing.latitude, 40.0);
    expect(listing.longitude, -3.5);
    expect(listing.hours, hasLength(1));
    expect(listing.hours.single.dayOfWeek, 0);
    expect(listing.hours.single.openMinutes, 540);
    expect(listing.hours.single.closeMinutes, 1110);
  });

  test('parses a log row with and without a previous status', () {
    final created = ModerationRepositoryImpl.parseLogEntry({
      'id': 1,
      'from_status': null,
      'to_status': 'pending',
      'actor_role': 'owner',
      'actor_id': 'u1',
      'reason': null,
      'created_at': '2026-11-03T10:00:00Z',
    });
    expect(created.from, isNull);
    expect(created.to, BusinessReviewStatus.pending);
    expect(created.actorRole, ReviewActorRole.owner);

    final rejected = ModerationRepositoryImpl.parseLogEntry({
      'id': 2,
      'from_status': 'pending',
      'to_status': 'rejected',
      'actor_role': 'reviewer',
      'actor_id': 'u2',
      'reason': 'Falta la dirección',
      'created_at': '2026-11-04T10:00:00Z',
    });
    expect(rejected.from, BusinessReviewStatus.pending);
    expect(rejected.reason, 'Falta la dirección');
    expect(rejected.actorRole, ReviewActorRole.reviewer);
  });
}
