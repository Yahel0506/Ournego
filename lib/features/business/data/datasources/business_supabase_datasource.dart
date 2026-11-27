import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ournego/features/business/data/errors/business_registration_exceptions.dart';
import 'package:ournego/features/business/data/models/business_submission_result_model.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/shared/services/image_compression_service.dart';
import 'package:ournego/shared/services/storage_paths.dart';

class BusinessSupabaseDatasource {
  final _supabase = Supabase.instance.client;
  final ImageCompressionService _imageCompression;

  BusinessSupabaseDatasource({ImageCompressionService? imageCompression})
    : _imageCompression = imageCompression ?? ImageCompressionService();

  /// Compresses [image] to WebP and uploads it under the business folder.
  /// Returns the object path inside the bucket.
  Future<String> _uploadBusinessImage(
    String businessId,
    BusinessImageData image,
  ) async {
    final CompressedImage compressed;
    try {
      compressed = await _imageCompression.compress(
        image.bytes,
        profile: ImageCompressionProfile.business,
      );
    } on ImageCompressionException {
      throw BusinessRegistrationImageUploadException();
    }
    final objectPath = StoragePaths.businessImage(
      businessId,
      const Uuid().v4(),
    );
    await _supabase.storage
        .from(StoragePaths.businessesBucket)
        .uploadBinary(
          objectPath,
          compressed.bytes,
          fileOptions: const FileOptions(
            cacheControl: '31536000',
            contentType: CompressedImage.contentType,
            upsert: false,
          ),
        );
    return objectPath;
  }

  /// Best-effort removal of an object whose row was never saved, so a failed
  /// write does not leave an orphan in Storage.
  Future<void> _discardUploadedImage(String objectPath) async {
    try {
      await _supabase.storage.from(StoragePaths.businessesBucket).remove([
        objectPath,
      ]);
    } catch (e) {
      debugPrint('Could not discard orphan image $objectPath: $e');
    }
  }

  Future<void> _runProtectedWrite(Future<void> Function() action) async {
    try {
      await action();
    } on BusinessRegistrationValidationException {
      // Raised by the action itself (for example a stale review request).
      rethrow;
    } on BusinessRegistrationImageUploadException {
      // Raised by the image compression step.
      rethrow;
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

  static String _minutesToSqlTime(int minutesFromMidnight) {
    final hours = minutesFromMidnight ~/ 60;
    final minutes = minutesFromMidnight % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }

  static int _mapAppDayToSqlDay(int appDay) {
    // App: 0 = Monday, 6 = Sunday
    // DB:  1 = Monday, 7 = Sunday
    return appDay + 1;
  }

  static List<Map<String, dynamic>> submissionHoursPayload(
    List<AppSchedule> hours,
  ) => [
    for (final schedule in hours)
      {
        'day_of_week': _mapAppDayToSqlDay(schedule.dayOfWeek),
        'opening_time': _minutesToSqlTime(schedule.openMinutes),
        'closing_time': _minutesToSqlTime(schedule.closeMinutes),
      },
  ];

  static Map<String, dynamic> submissionRpcArguments({
    required String businessId,
    required String name,
    required String description,
    required int category,
    required String address,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String imageObject,
    required String imageUrl,
    required List<AppSchedule> hours,
  }) => {
    'p_listing': {
      'business_id': businessId,
      'name': name,
      'description': description,
      'type': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber.trim().isEmpty ? null : phoneNumber.trim(),
      'image_object': imageObject,
      'image_url': imageUrl,
    },
    'p_hours': submissionHoursPayload(hours),
  };

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

  Future<BusinessSubmissionResultModel> submitBusinessListing({
    required String businessId,
    required String name,
    required String description,
    required int category,
    required String address,
    required double latitude,
    required double longitude,
    required BusinessImageData image,
    required String phoneNumber,
    required List<AppSchedule> hours,
  }) async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw BusinessRegistrationUnauthorizedException();
      }
      final objectPath = await _uploadBusinessImage(businessId, image);
      final imageUrl = _supabase.storage
          .from(StoragePaths.businessesBucket)
          .getPublicUrl(objectPath);
      final dynamic response;
      try {
        response = await _supabase.rpc(
          'submit_business_listing',
          params: submissionRpcArguments(
            businessId: businessId,
            name: name,
            description: description,
            category: category,
            address: address,
            latitude: latitude,
            longitude: longitude,
            phoneNumber: phoneNumber,
            imageObject: objectPath,
            imageUrl: imageUrl,
            hours: hours,
          ),
        );
      } catch (_) {
        await _discardUploadedImage(objectPath);
        rethrow;
      }
      final data = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      return BusinessSubmissionResultModel.fromJson(data);
    } on BusinessRegistrationUnauthorizedException {
      rethrow;
    } on TimeoutException {
      throw BusinessRegistrationNetworkException();
    } on SocketException {
      throw BusinessRegistrationNetworkException();
    } on StorageException {
      throw BusinessRegistrationImageUploadException();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      final code = (e.code ?? '').toLowerCase();
      if (message.contains('profile_required')) {
        throw const BusinessRegistrationRuleException('profile_required');
      }
      if (message.contains('business_daily_limit')) {
        throw const BusinessRegistrationRuleException('business_daily_limit');
      }
      if (message.contains('business_active_limit')) {
        throw const BusinessRegistrationRuleException('business_active_limit');
      }
      if (message.contains('invalid_listing') || code == '23514') {
        throw const BusinessRegistrationRuleException('invalid_listing');
      }
      if (code == '42501') throw BusinessRegistrationUnauthorizedException();
      if (code == '23505' || message.contains('duplicate')) {
        throw BusinessRegistrationDuplicateException();
      }
      throw BusinessRegistrationUnknownException();
    } catch (e) {
      if (e is BusinessRegistrationRuleException ||
          e is BusinessRegistrationNetworkException ||
          e is BusinessRegistrationImageUploadException ||
          e is BusinessRegistrationDuplicateException ||
          e is BusinessRegistrationUnknownException) {
        rethrow;
      }
      throw BusinessRegistrationUnknownException();
    }
  }

  /// Moves a rejected or withdrawn listing back to `pending`. The status
  /// filter makes a stale request (already pending or approved) fail instead of
  /// silently doing nothing; the server (RLS + trigger) still has the final say.
  Future<void> submitBusinessForReview({required String businessId}) async {
    await _runProtectedWrite(() async {
      final updated = await _supabase
          .from('businesses')
          .update({'status': 'pending'})
          .eq('business_id', businessId)
          .inFilter('status', ['rejected', 'withdrawn'])
          .select('business_id');
      if (updated.isEmpty) {
        throw BusinessRegistrationValidationException();
      }
    });
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
      final storagePath = await _uploadBusinessImage(businessId, image);
      final imageUrl = _supabase.storage
          .from(StoragePaths.businessesBucket)
          .getPublicUrl(storagePath);

      try {
        final existing = await _supabase
            .from('businesses')
            .select('images')
            .eq('business_id', businessId)
            .single();
        final rawImages = (existing['images'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList();
        await _supabase
            .from('businesses')
            .update({
              'images': [...rawImages, imageUrl],
            })
            .eq('business_id', businessId);
      } catch (_) {
        await _discardUploadedImage(storagePath);
        rethrow;
      }
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

      // The object path comes from the URL, so photos stored with the old
      // naming scheme are removed too.
      final storagePath = StoragePaths.objectPathFromPublicUrl(
        imageUrl,
        StoragePaths.businessesBucket,
      );
      if (storagePath != null) {
        await _supabase.storage.from(StoragePaths.businessesBucket).remove([
          storagePath,
        ]);
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
