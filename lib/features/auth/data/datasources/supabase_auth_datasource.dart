import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class SupabaseAuthDatasource {
  final _supabase = Supabase.instance.client;

  Future<User> signUpWithEmail(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final rawUser = res.user;

    if (rawUser != null) {
      await _supabase.from('users').insert({
        'id': rawUser.id,
        'has_profile': false,
      });
      return rawUser;
    } else {
      throw Exception('signup-error');
    }
  }

  Future<User> logInWithEmail(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final User? rawUser = res.user;

    if (rawUser != null) {
      return rawUser;
    } else {
      throw Exception('login-error');
    }
  }

  Future<bool> checkHasProfile() async {
    final String userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('users')
        .select('has_profile')
        .eq('id', userId)
        .single();

    return data['has_profile'] as bool;
  }

  Stream<List<Map<String, dynamic>>> getProfile({String? id}) {
    if (id != null) {
      final data = _supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', id);

      return data;
    } else {
      final String userId = _supabase.auth.currentUser!.id;

      final data = _supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', userId);

      return data;
    }
  }

  Future<void> updateProfilePicture(File profilePicture) async {
    final String userId = _supabase.auth.currentUser!.id;
    await _supabase.storage
        .from('profile_pictures')
        .upload(
          '$userId${p.extension(profilePicture.path)}',
          profilePicture,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
  }

  Future<void> updateUserName(String name) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('users').update({'name': name}).eq('id', userId);
  }

  Future<void> confirmHasProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('users')
        .update({'has_profile': true})
        .eq('id', userId);
  }
}
