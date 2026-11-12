import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/network/network_error_classifier.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/data/datasources/supabase_moderation_datasource.dart';
import 'package:ournego/features/moderation/data/errors/moderation_exceptions.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final SupabaseModerationDatasource datasource;

  ModerationRepositoryImpl({required this.datasource});

  Failure _readFailure(Object e) {
    if (isNetworkError(e)) return NetworkFailure();
    if (isSessionExpiredError(e)) return SessionExpiredFailure();
    return ServerFailure();
  }

  @override
  Future<Either<Failure, bool>> isReviewer() async {
    try {
      return Right(await datasource.isReviewer());
    } catch (e) {
      return Left(_readFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ReviewListing>>> getListings({
    required BusinessReviewStatus status,
  }) async {
    try {
      final rows = await datasource.getListings(status: status);
      return Right(rows.map(parseListing).toList(growable: false));
    } catch (e) {
      return Left(_readFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ReviewLogEntry>>> getReviewLog({
    required String businessId,
  }) async {
    try {
      final rows = await datasource.getReviewLog(businessId: businessId);
      return Right(rows.map(parseLogEntry).toList(growable: false));
    } catch (e) {
      return Left(_readFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> decide({
    required String businessId,
    required ReviewDecision decision,
    String? reason,
  }) async {
    try {
      await datasource.decide(
        businessId: businessId,
        decision: decision,
        reason: reason,
      );
      return const Right(null);
    } on ModerationNotAuthorizedException {
      return Left(ModerationNotAuthorizedFailure());
    } on ModerationReasonRequiredException {
      return Left(ModerationReasonRequiredFailure());
    } on ModerationStaleException {
      return Left(ModerationStaleFailure());
    } catch (e) {
      return Left(_readFailure(e));
    }
  }

  static ReviewListing parseListing(Map<String, dynamic> row) {
    return ReviewListing(
      id: row['business_id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      category: row['type'] as int? ?? 0,
      address: row['address'] as String? ?? '',
      phoneNumber: _nonEmpty(row['phone_number'] as String?),
      images: (row['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      hours: _parseHours(row['hours']),
      status: BusinessReviewStatus.fromWire(row['status'] as String?),
      submittedAt: _parseDate(row['submitted_at']),
      reviewedAt: _parseDate(row['reviewed_at']),
      reason: _nonEmpty(row['rejection_reason'] as String?),
    );
  }

  static ReviewLogEntry parseLogEntry(Map<String, dynamic> row) {
    final from = row['from_status'] as String?;
    return ReviewLogEntry(
      id: (row['id'] as num?)?.toInt() ?? 0,
      from: from == null ? null : BusinessReviewStatus.fromWire(from),
      to: BusinessReviewStatus.fromWire(row['to_status'] as String?),
      actorRole: ReviewActorRole.fromWire(row['actor_role'] as String?),
      actorId: row['actor_id'] as String?,
      reason: _nonEmpty(row['reason'] as String?),
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
    );
  }

  /// `business_hours` rows (day 1 = Monday, `HH:MM:SS` times) to schedules.
  /// Rows that cannot be read are skipped.
  static List<AppSchedule> _parseHours(Object? raw) {
    if (raw is! List) return const [];
    final hours = <AppSchedule>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final day = item['day_of_week'];
      final open = _parseMinutes(item['opening_time']);
      final close = _parseMinutes(item['closing_time']);
      if (day is! int || open == null || close == null) continue;
      hours.add(
        AppSchedule(dayOfWeek: day - 1, openMinutes: open, closeMinutes: close),
      );
    }
    return hours;
  }

  static int? _parseMinutes(Object? raw) {
    if (raw is! String) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
