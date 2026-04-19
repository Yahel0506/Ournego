import 'dart:async';
import 'dart:io' show SocketException;

import 'package:ournego/features/business/data/errors/business_registration_exceptions.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSupabaseDatasource {
  final _supabase = Supabase.instance.client;

  String _minutesToSqlTime(int minutesFromMidnight) {
    final hours = minutesFromMidnight ~/ 60;
    final minutes = minutesFromMidnight % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }

  int _mapAppDayToSqlDay(int appDay) {
    // App: 0 = Monday, 6 = Sunday
    // DB:  1 = Monday, 7 = Sunday
    return appDay + 1;
  }

  Future<bool> isSignedIn() async {
    try {
      final user = _supabase.auth.currentUser;
      return user != null;
    } catch (_) {
      return false;
    }
  }

  Future<String> registerBusiness(Map<String, dynamic> businessData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw BusinessRegistrationUnauthorizedException();
      }

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

  Future<void> uploadBusinessImage(
    BusinessImageData image,
    String business,
  ) async {
    try {
      final fileName = image.fileName.trim().isNotEmpty
          ? image.fileName
          : 'business-image.jpg';
      final storagePath = '$business/$fileName';

      await _supabase.storage
          .from('businesses_pictures')
          .uploadBinary(
            storagePath,
            image.bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      final imageUrl = _supabase.storage
          .from('businesses_pictures')
          .getPublicUrl(storagePath);

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

  Future<void> setBusinessHours(
    String businessId,
    List<AppSchedule> hours,
  ) async {
    try {
      await Future.wait(
        hours.map((schedule) async {
          final openTime = _minutesToSqlTime(schedule.openMinutes);
          final closeTime = _minutesToSqlTime(schedule.closeMinutes);
          final dayOfWeek = _mapAppDayToSqlDay(schedule.dayOfWeek);

          await _supabase.from('business_hours').insert({
            'business_id': businessId,
            'day_of_week': dayOfWeek,
            'opening_time': openTime,
            'closing_time': closeTime,
          });
        }),
      );
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
