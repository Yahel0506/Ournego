import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

ReviewListing fakeReviewListing(
  String id, {
  String? name,
  BusinessReviewStatus status = BusinessReviewStatus.pending,
  String? address,
  String? phoneNumber,
  bool withoutPhone = false,
  List<String>? images,
  double? latitude = 40.0,
  double? longitude = -3.0,
  List<AppSchedule>? hours,
}) {
  return ReviewListing(
    id: id,
    name: name ?? 'Negocio $id',
    description: 'Descripción de $id',
    category: 0,
    address: address ?? 'Calle $id',
    // Unique per id so two fakes are not flagged as duplicates of each other.
    phoneNumber: withoutPhone
        ? null
        : phoneNumber ??
              '600${id.codeUnits.fold<int>(111000, (a, b) => a * 7 + b) % 1000000}',
    images: images ?? ['https://example.test/$id.jpg'],
    latitude: latitude,
    longitude: longitude,
    hours:
        hours ??
        const [AppSchedule(dayOfWeek: 0, openMinutes: 540, closeMinutes: 1080)],
    status: status,
    submittedAt: DateTime(2026, 11, 3),
    reviewedAt: status == BusinessReviewStatus.approved
        ? DateTime(2026, 11, 4)
        : null,
  );
}

class DecisionCall {
  DecisionCall(this.businessId, this.decision, this.reason);

  final String businessId;
  final ReviewDecision decision;
  final String? reason;
}

/// In-memory moderation repository. A decision moves the listing between the
/// two lists, like the server would.
class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({
    this.reviewer = true,
    List<ReviewListing>? pending,
    List<ReviewListing>? approved,
    this.log = const [],
    this.decideFailure,
  }) : pending = pending ?? [],
       approved = approved ?? [];

  bool reviewer;
  final List<ReviewListing> pending;
  final List<ReviewListing> approved;
  List<ReviewLogEntry> log;
  Failure? decideFailure;
  final List<DecisionCall> calls = [];

  @override
  Future<Either<Failure, bool>> isReviewer() async => Right(reviewer);

  @override
  Future<Either<Failure, List<ReviewListing>>> getListings({
    required BusinessReviewStatus status,
  }) async {
    if (!reviewer) return const Right([]);
    return Right(
      List.of(status == BusinessReviewStatus.pending ? pending : approved),
    );
  }

  @override
  Future<Either<Failure, List<ReviewLogEntry>>> getReviewLog({
    required String businessId,
  }) async => Right(log);

  @override
  Future<Either<Failure, void>> decide({
    required String businessId,
    required ReviewDecision decision,
    String? reason,
  }) async {
    calls.add(DecisionCall(businessId, decision, reason));
    final failure = decideFailure;
    if (failure != null) return Left(failure);
    final source = decision == ReviewDecision.withdraw ? approved : pending;
    final index = source.indexWhere((l) => l.id == businessId);
    if (index == -1) return Left(ModerationStaleFailure());
    final listing = source.removeAt(index);
    if (decision == ReviewDecision.approve) {
      approved.add(
        fakeReviewListing(listing.id, status: BusinessReviewStatus.approved),
      );
    }
    return const Right(null);
  }
}
