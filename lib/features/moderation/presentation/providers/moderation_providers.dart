import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/data/datasources/supabase_moderation_datasource.dart';
import 'package:ournego/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';
import 'package:ournego/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:ournego/features/moderation/domain/usecases/check_is_reviewer_usecase.dart';
import 'package:ournego/features/moderation/domain/usecases/decide_business_review_usecase.dart';
import 'package:ournego/features/moderation/domain/usecases/get_review_listings_usecase.dart';
import 'package:ournego/features/moderation/domain/usecases/get_review_log_usecase.dart';

// |---------------------------------| \\
// |------- LAYER 1: DATASOURCES ---| \\
// |---------------------------------| \\

final moderationDatasourceProvider = Provider<SupabaseModerationDatasource>(
  (ref) => SupabaseModerationDatasource(),
);

// |---------------------------------| \\
// |------- LAYER 2: REPOSITORIES --| \\
// |---------------------------------| \\

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final datasource = ref.watch(moderationDatasourceProvider);
  return ModerationRepositoryImpl(datasource: datasource);
});

// |---------------------------------| \\
// |------- LAYER 3: USECASES ------| \\
// |---------------------------------| \\

final checkIsReviewerUsecaseProvider = Provider<CheckIsReviewerUsecase>((ref) {
  return CheckIsReviewerUsecase(
    repository: ref.watch(moderationRepositoryProvider),
  );
});

final getReviewListingsUsecaseProvider = Provider<GetReviewListingsUsecase>((
  ref,
) {
  return GetReviewListingsUsecase(
    repository: ref.watch(moderationRepositoryProvider),
  );
});

final getReviewLogUsecaseProvider = Provider<GetReviewLogUsecase>((ref) {
  return GetReviewLogUsecase(
    repository: ref.watch(moderationRepositoryProvider),
  );
});

final decideBusinessReviewUsecaseProvider =
    Provider<DecideBusinessReviewUsecase>((ref) {
      return DecideBusinessReviewUsecase(
        repository: ref.watch(moderationRepositoryProvider),
      );
    });

// |---------------------------------| \\
// |------- LAYER 4: STATE ----------| \\
// |---------------------------------| \\

/// Whether the signed-in account is a reviewer. It only decides what the UI
/// offers (menu entry, screen); the server checks every read and decision.
///
/// A failed check counts as "not a reviewer" so a network error never opens the
/// moderation screen; the screen offers a retry through `ref.invalidate`.
final isReviewerProvider = FutureProvider<bool>((ref) async {
  // Re-run on every login/logout so a previous session's answer is not reused.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  final result = await ref.watch(checkIsReviewerUsecaseProvider)();
  return result.fold((_) => false, (isReviewer) => isReviewer);
});

/// Listings in a status for the queue (`pending`) or the published tab
/// (`approved`).
final reviewListingsProvider = FutureProvider.autoDispose
    .family<List<ReviewListing>, BusinessReviewStatus>((ref, status) async {
      final result = await ref.watch(getReviewListingsUsecaseProvider)(
        status: status,
      );
      return result.fold((failure) => throw failure, (items) => items);
    });

/// History of one listing, newest first.
final reviewLogProvider = FutureProvider.autoDispose
    .family<List<ReviewLogEntry>, String>((ref, businessId) async {
      final result = await ref.watch(getReviewLogUsecaseProvider)(
        businessId: businessId,
      );
      return result.fold((failure) => throw failure, (entries) => entries);
    });
