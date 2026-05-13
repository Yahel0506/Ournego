import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/map/data/datasources/map_exceptions.dart';
import 'package:ournego/features/map/domain/entities/business_hours.dart';

class SupabaseMapDatasource {
  final _supabase = Supabase.instance.client;

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const MapAuthenticationRequiredException();
    }
    return user.id;
  }

  Stream<List<Map<String, dynamic>>> getBusinesses() {
    return _supabase.from('businesses').stream(primaryKey: ['business_id']);
  }

  Future<Map<String, dynamic>?> getBusinessById(String businessId) async {
    final data = await _supabase
        .from('businesses')
        .select()
        .eq('business_id', businessId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(data);
  }

  Future<void> addBusinessToFavorites(String businessId) async {
    final userId = _requireUserId();

    await _supabase.from('user_favorites').insert({
      'user_id': userId,
      'business_id': businessId,
    });
  }

  Future<void> removeBusinessFromFavorites(String businessId) async {
    final userId = _requireUserId();

    await _supabase
        .from('user_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('business_id', businessId);
  }

  Stream<bool> isBusinessFavorite(String businessId) {
    final userId = _requireUserId();

    final isFavorite = _supabase
        .from('user_favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.any((fav) => fav['business_id'] == businessId));

    return isFavorite;
  }

  Future<Map<String, List<BusinessHours>>> getBusinessHoursByBusinessId(
    List<String> businessIds,
  ) async {
    if (businessIds.isEmpty) {
      return <String, List<BusinessHours>>{};
    }

    try {
      final rows = await _supabase
          .from('business_hours')
          .select('business_id, day_of_week, opening_time, closing_time')
          .inFilter('business_id', businessIds);

      final result = <String, List<BusinessHours>>{};
      for (final row in rows) {
        final data = Map<String, dynamic>.from(row);
        final businessId = data['business_id'] as String?;
        final dayOfWeekDb = data['day_of_week'] as int?;
        final openingTime = data['opening_time'] as String?;
        final closingTime = data['closing_time'] as String?;
        if (businessId == null ||
            dayOfWeekDb == null ||
            openingTime == null ||
            closingTime == null) {
          continue;
        }

        final dayOfWeek = dayOfWeekDb - 1;
        if (dayOfWeek < 0 || dayOfWeek > 6) {
          continue;
        }

        final parsedOpenMinutes = _parseSqlTimeToMinutes(openingTime);
        final parsedCloseMinutes = _parseSqlTimeToMinutes(closingTime);
        if (parsedOpenMinutes == null || parsedCloseMinutes == null) {
          continue;
        }

        result
            .putIfAbsent(businessId, () => <BusinessHours>[])
            .add(
              BusinessHours(
                dayOfWeek: dayOfWeek,
                openMinutes: parsedOpenMinutes,
                closeMinutes: parsedCloseMinutes,
              ),
            );
      }

      return result;
    } catch (_) {
      // Keep map resilient while table/policies are being rolled out.
      return <String, List<BusinessHours>>{};
    }
  }

  Future<Map<String, int>> getBusinessVisitCountsByBusinessId(
    List<String> businessIds,
  ) async {
    if (businessIds.isEmpty) {
      return <String, int>{};
    }

    try {
      final rows = await _supabase
          .from('user_interactions')
          .select('business_id')
          .eq('interaction_type', 'view_business_profile')
          .inFilter('business_id', businessIds);

      final counts = <String, int>{};
      for (final row in rows) {
        final data = Map<String, dynamic>.from(row);
        final businessId = data['business_id'] as String?;
        if (businessId == null) {
          continue;
        }

        counts[businessId] = (counts[businessId] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      // Keep map resilient while table/policies are being rolled out.
      return <String, int>{};
    }
  }

  Future<void> trackBusinessInteraction({
    required String businessId,
    required String source,
    required String interactionType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('user_interactions').insert({
      'business_id': businessId,
      'user_id': userId,
      'source': source,
      'interaction_type': interactionType,
    });
  }

  int? _parseSqlTimeToMinutes(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) {
      return null;
    }
    return (hours * 60) + minutes;
  }
}
