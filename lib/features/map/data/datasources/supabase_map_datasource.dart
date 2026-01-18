import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMapDatasource {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getBusinesses() {
    return _supabase.from('businesses').stream(primaryKey: ['id']);
  }
}
