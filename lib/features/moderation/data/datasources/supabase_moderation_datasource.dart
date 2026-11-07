import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/data/errors/moderation_exceptions.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';

/// Reads the moderation queue and applies decisions.
///
/// Access is decided by the server (RLS + trigger `enforce_business_status_change`
/// + `business_review_log`); nothing here grants anything. A non-reviewer simply
/// gets no rows, or an error when trying to decide.
class SupabaseModerationDatasource {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const _listingColumns =
      'business_id, name, description, type, address, phone_number, images, '
      'status, submitted_at, reviewed_at, rejection_reason';

  Future<bool> isReviewer() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _supabase
        .from('reviewers')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  Future<List<Map<String, dynamic>>> getListings({
    required BusinessReviewStatus status,
  }) async {
    final filtered = _supabase
        .from('businesses')
        .select(_listingColumns)
        .eq('status', status.wire);
    final rows = status == BusinessReviewStatus.pending
        ? await filtered.order('submitted_at', ascending: true)
        : await filtered.order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getReviewLog({
    required String businessId,
  }) async {
    final rows = await _supabase
        .from('business_review_log')
        .select(
          'id, from_status, to_status, actor_role, actor_id, reason, created_at',
        )
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> decide({
    required String businessId,
    required ReviewDecision decision,
    String? reason,
  }) async {
    try {
      final updated = await _supabase
          .from('businesses')
          .update({
            'status': decision.resultingStatus.wire,
            if (decision.requiresReason) 'rejection_reason': reason,
          })
          .eq('business_id', businessId)
          .eq('status', decision.requiredStatus.wire)
          .select('business_id');
      // RLS hides rows from non-reviewers and the status filter hides listings
      // that already moved on: either way nothing changed.
      if (updated.isEmpty) throw ModerationStaleException();
    } on PostgrestException catch (e) {
      final code = (e.code ?? '').toLowerCase();
      if (code == '42501') throw ModerationNotAuthorizedException();
      if (code == '23514') throw ModerationReasonRequiredException();
      rethrow;
    }
  }
}
