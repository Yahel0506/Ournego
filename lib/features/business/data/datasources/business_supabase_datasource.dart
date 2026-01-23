import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSupabaseDatasource {
  final _supabase = Supabase.instance.client;

  Future<Session?> isLoggedIn() async {
    final session = await _supabase.auth.currentSession;
    return session;
  }
}
