import 'dart:io';

import 'package:ournego/features/business/domain/entitites/app_schedule.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSupabaseDatasource {
  final _supabase = Supabase.instance.client;

  // TODO: Move to Auth Datasource
  Future<Session?> isLoggedIn() async {
    final session = await _supabase.auth.currentSession;
    return session;
  }

  Future<String> registerBusiness(Map<String, dynamic> businessData) async {
    final response = await _supabase
        .from('businesses')
        .insert(businessData)
        .select('business_id')
        .single();
    return response['business_id'] as String;
  }

  Future<void> uploadBusinessImage(File image, String business) async {
    await _supabase.storage
        .from('businesses_pictures')
        .upload(
          '${p.basename(image.path)}',
          image,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    final imageUrl = _supabase.storage
        .from('businesses_pictures')
        .getPublicUrl('${p.basename(image.path)}');

    await _supabase
        .from('businesses')
        .update({
          'images': [imageUrl],
        })
        .eq('business_id', business);
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
}
