import 'dart:async';
import 'dart:io' show SocketException;

import 'package:ournego/features/business/data/errors/business_registration_exceptions.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSupabaseDatasource {
  final _supabase = Supabase.instance.client;

  Future<void> _runProtectedWrite(Future<void> Function() action) async {
    try {
      await action();
    } on TimeoutException {
      throw BusinessRegistrationNetworkException();
    } on SocketException {
      throw BusinessRegistrationNetworkException();
    } on StorageException {
      throw BusinessRegistrationImageUploadException();
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

  Future<void> upsertBusinessName({
    required String businessId,
    required String name,
  }) async {
    await _runProtectedWrite(() async {
      await _supabase
          .from('businesses')
          .update({'name': name})
          .eq('business_id', businessId);
    });
  }

  Future<void> upsertBusinessDescription({
    required String businessId,
    required String description,
  }) async {
    await _runProtectedWrite(() async {
      await _supabase
          .from('businesses')
          .update({'description': description})
          .eq('business_id', businessId);
    });
  }

  Future<void> upsertBusinessLocation({
    required String businessId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await _runProtectedWrite(() async {
      await _supabase
          .from('businesses')
          .update({
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
          })
          .eq('business_id', businessId);
    });
  }

  Future<void> upsertBusinessCategory({
    required String businessId,
    required int category,
  }) async {
    await _runProtectedWrite(() async {
      await _supabase
          .from('businesses')
          .update({'type': category})
          .eq('business_id', businessId);
    });
  }

  Future<void> insertBusinessImage({
    required String businessId,
    required BusinessImageData image,
  }) async {
    await _runProtectedWrite(() async {
      final fileName = image.fileName.trim().isNotEmpty
          ? image.fileName
          : 'business-image.jpg';
      final storagePath = '$businessId/$fileName';

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

      final existing = await _supabase
          .from('businesses')
          .select('images')
          .eq('business_id', businessId)
          .single();

      final rawImages = (existing['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();

      final updatedImages = [...rawImages, imageUrl];

      await _supabase
          .from('businesses')
          .update({'images': updatedImages})
          .eq('business_id', businessId);
    });
  }

  Future<void> deleteBusinessImage({
    required String businessId,
    required String imageUrl,
  }) async {
    await _runProtectedWrite(() async {
      final existing = await _supabase
          .from('businesses')
          .select('images')
          .eq('business_id', businessId)
          .single();

      final rawImages = (existing['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();

      rawImages.remove(imageUrl);

      await _supabase
          .from('businesses')
          .update({'images': rawImages})
          .eq('business_id', businessId);

      final bucket = _supabase.storage.from('businesses_pictures');
      final uri = Uri.tryParse(imageUrl);
      final path = uri?.pathSegments.skipWhile(
        (s) => s != 'businesses_pictures',
      );
      if (path != null && path.isNotEmpty) {
        final storagePath = path.skip(1).join('/');
        if (storagePath.isNotEmpty) {
          await bucket.remove([storagePath]);
        }
      }
    });
  }

  Future<void> upsertBusinessPhoneNumber({
    required String businessId,
    required String phoneNumber,
  }) async {
    await _runProtectedWrite(() async {
      await _supabase
          .from('businesses')
          .update({'phone_number': phoneNumber})
          .eq('business_id', businessId);
    });
  }

  Future<void> deleteBusinessPhoneNumber({required String businessId}) async {
    await _runProtectedWrite(() async {
      await _supabase
          .from('businesses')
          .update({'phone_number': null})
          .eq('business_id', businessId);
    });
  }

  Future<void> upsertBusinessHours({
    required String businessId,
    required List<AppSchedule> hours,
  }) async {
    await _runProtectedWrite(() async {
      if (hours.isEmpty) {
        await _supabase
            .from('business_hours')
            .delete()
            .eq('business_id', businessId);
        return;
      }

      final rows = hours
          .map((schedule) {
            return {
              'business_id': businessId,
              'day_of_week': _mapAppDayToSqlDay(schedule.dayOfWeek),
              'opening_time': _minutesToSqlTime(schedule.openMinutes),
              'closing_time': _minutesToSqlTime(schedule.closeMinutes),
            };
          })
          .toList(growable: false);

      try {
        await _supabase
            .from('business_hours')
            .upsert(rows, onConflict: 'business_id,day_of_week');
      } on PostgrestException {
        // Fallback when the composite unique constraint is not available for
        // PostgREST upsert. We update by day and insert missing rows.
        for (final row in rows) {
          final dayOfWeek = row['day_of_week'] as int;
          final updatedRows = await _supabase
              .from('business_hours')
              .update({
                'opening_time': row['opening_time'],
                'closing_time': row['closing_time'],
              })
              .eq('business_id', businessId)
              .eq('day_of_week', dayOfWeek)
              .select('day_of_week');

          if (updatedRows.isEmpty) {
            await _supabase.from('business_hours').insert(row);
          }
        }
      }

      final incomingDays = rows.map((row) => row['day_of_week'] as int).toSet();

      final existingRows = await _supabase
          .from('business_hours')
          .select('day_of_week')
          .eq('business_id', businessId);

      final existingDays = existingRows
          .map((row) => (row['day_of_week'] as num?)?.toInt())
          .whereType<int>()
          .toSet();

      final daysToDelete = existingDays.difference(incomingDays).toList();
      if (daysToDelete.isNotEmpty) {
        await _supabase
            .from('business_hours')
            .delete()
            .eq('business_id', businessId)
            .inFilter('day_of_week', daysToDelete);
      }
    });
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

  Future<Map<String, dynamic>?> getOwnedBusiness() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    final ownedBusiness = await _supabase
        .from('businesses')
        .select()
        .eq('owner_id', user.id)
        .limit(1)
        .maybeSingle();

    if (ownedBusiness == null) {
      return null;
    }

    final businessId = ownedBusiness['business_id'] as String?;
    if (businessId == null) {
      return null;
    }

    final hoursRows = await _supabase
        .from('business_hours')
        .select('day_of_week, opening_time, closing_time')
        .eq('business_id', businessId);

    final hours = <AppSchedule>[];
    for (final row in hoursRows) {
      final data = Map<String, dynamic>.from(row);
      final dayOfWeekDb = data['day_of_week'] as int?;
      final openingTime = data['opening_time'] as String?;
      final closingTime = data['closing_time'] as String?;
      if (dayOfWeekDb == null || openingTime == null || closingTime == null) {
        continue;
      }

      final dayOfWeek = dayOfWeekDb - 1;
      if (dayOfWeek < 0 || dayOfWeek > 6) {
        continue;
      }

      final openMinutes = _parseSqlTimeToMinutes(openingTime);
      final closeMinutes = _parseSqlTimeToMinutes(closingTime);
      if (openMinutes == null || closeMinutes == null) {
        continue;
      }

      hours.add(
        AppSchedule(
          dayOfWeek: dayOfWeek,
          openMinutes: openMinutes,
          closeMinutes: closeMinutes,
        ),
      );
    }

    final payload = Map<String, dynamic>.from(ownedBusiness);
    payload['hours'] = hours;
    return payload;
  }

  Future<Map<String, dynamic>> getBusinessPanelMetrics({
    required String businessId,
  }) async {
    final reviewsRows = await _supabase
        .from('reviews')
        .select('rating')
        .eq('business_id', businessId);
    final ratings = reviewsRows
        .map((row) => (row['rating'] as num?)?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final averageRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    final nowUtc = DateTime.now().toUtc();
    final fromUtc = nowUtc.subtract(const Duration(days: 30));
    final interactionsRows = await _supabase
        .from('user_interactions')
        .select('id')
        .eq('business_id', businessId)
        .gte('created_at', fromUtc.toIso8601String());

    final favoritesRows = await _supabase
        .from('user_favorites')
        .select('id')
        .eq('business_id', businessId);

    return <String, dynamic>{
      'average_rating': averageRating,
      'monthly_interactions': interactionsRows.length,
      'favorite_count': favoritesRows.length,
    };
  }
}
