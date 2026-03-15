import 'dart:async';
import 'dart:io';

import 'package:ournego/features/business/data/errors/business_registration_exceptions.dart';
import 'package:ournego/features/business/domain/entitites/app_schedule.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSupabaseDatasource {
  final _supabase = Supabase.instance.client;

  // TODO: Move to Auth Datasource
  Stream<bool> isLoggedIn() async* {
    // Emit current auth state immediately (important on web where
    // onAuthStateChange may not emit right away).
    yield _supabase.auth.currentSession != null;

    yield* _supabase.auth.onAuthStateChange
        .map((event) => event.session != null)
        .distinct();
  }

  Future<String> registerBusiness(Map<String, dynamic> businessData) async {
    try {
      final response = await _supabase
          .from('businesses')
          .insert(businessData)
          .select('business_id')
          .single();
      return response['business_id'] as String;
    } on TimeoutException {
      throw BusinessRegistrationNetworkException();
    } on SocketException {
      throw BusinessRegistrationNetworkException();
    } on PostgrestException catch (e) {
      final code = (e.code ?? '').toLowerCase();
      final message = e.message.toLowerCase();

      if (code == '42501' || message.contains('permission denied')) {
        throw BusinessRegistrationUnauthorizedException();
      }

      if (code == '23505' || message.contains('duplicate')) {
        throw BusinessRegistrationDuplicateException();
      }

      if (code == '23514' ||
          message.contains('violates') ||
          message.contains('invalid')) {
        throw BusinessRegistrationValidationException();
      }

      throw BusinessRegistrationUnknownException();
    } catch (_) {
      throw BusinessRegistrationUnknownException();
    }
  }

  Future<void> uploadBusinessImage(File image, String business) async {
    try {
      await _supabase.storage
          .from('businesses_pictures')
          .upload(
            p.basename(image.path),
            image,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      final imageUrl = _supabase.storage
          .from('businesses_pictures')
          .getPublicUrl(p.basename(image.path));

      await _supabase
          .from('businesses')
          .update({
            'images': [imageUrl],
          })
          .eq('business_id', business);
    } on TimeoutException {
      throw BusinessRegistrationNetworkException();
    } on SocketException {
      throw BusinessRegistrationNetworkException();
    } on StorageException {
      throw BusinessRegistrationImageUploadException();
    } on PostgrestException {
      throw BusinessRegistrationImageUploadException();
    } catch (_) {
      throw BusinessRegistrationUnknownException();
    }
  }

  // TODO: Improve this method
  Future<void> setBusinessHours(
    String businessId,
    List<AppSchedule> hours,
  ) async {
    await Future.wait(
      hours.map((schedule) async {
        // Convert TimeOfDay to "HH:mm" format
        final openTime =
            '${schedule.openTime.hour.toString().padLeft(2, '0')}:${schedule.openTime.minute.toString().padLeft(2, '0')}';
        final closeTime =
            '${schedule.closeTime.hour.toString().padLeft(2, '0')}:${schedule.closeTime.minute.toString().padLeft(2, '0')}';

        await _supabase.from('business_hours').insert({
          'business_id': businessId,
          'day_of_week': schedule.dayOfWeek,
          'opening_time': openTime,
          'closing_time': closeTime,
        });
      }),
    );
  }

  Future<bool> checkIfOwner() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return false;
    }
    final String userId = user.id;
    final response = await _supabase
        .from('businesses')
        .select('business_id')
        .eq('owner_id', userId)
        .limit(1)
        .maybeSingle();

    return response != null;
  }
}
