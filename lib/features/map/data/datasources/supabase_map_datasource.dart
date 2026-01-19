import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMapDatasource {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getBusinesses() {
    return _supabase.from('businesses').stream(primaryKey: ['id']);
  }

  Future<void> addBusinessToFavorites(String businessId) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('user_favorites').insert({
      'user_id': userId,
      'business_id': businessId});
  }

  Future<void> removeBusinessFromFavorites(String businessId) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('user_favorites').delete().eq('user_id', userId).eq('business_id', businessId);
  }

  Stream<bool> isBusinessFavorite(String businessId) {
    final userId = _supabase.auth.currentUser!.id;

    final isFavorite = _supabase
        .from('user_favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.any((fav) => fav['business_id'] == businessId));

    return isFavorite;
  }
}
