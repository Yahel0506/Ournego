import 'package:flutter/foundation.dart' show debugPrint;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ournego/features/feedback/data/models/feedback_report_model.dart';
import 'package:ournego/shared/services/image_compression_service.dart';
import 'package:ournego/shared/services/storage_paths.dart';

class FeedbackDatasource {
  final _supabase = Supabase.instance.client;
  final ImageCompressionService _imageCompression;

  FeedbackDatasource({ImageCompressionService? imageCompression})
    : _imageCompression = imageCompression ?? ImageCompressionService();

  /// Uploads the screenshot as WebP under `<userId>/<uuid>.webp` and stores
  /// its public URL with the report. If the row cannot be saved the file is
  /// removed again.
  Future<void> sendFeedback(FeedbackReportModel report) async {
    final compressed = await _imageCompression.compress(
      await report.attachment.readAsBytes(),
      profile: ImageCompressionProfile.attachment,
    );
    final owner = _supabase.auth.currentUser?.id ?? 'anonymous';
    final objectPath = StoragePaths.feedbackAttachment(
      owner,
      const Uuid().v4(),
    );
    final bucket = _supabase.storage.from(StoragePaths.feedbackBucket);

    await bucket.uploadBinary(
      objectPath,
      compressed.bytes,
      fileOptions: const FileOptions(contentType: CompressedImage.contentType),
    );

    try {
      await _supabase
          .from('feedback')
          .insert(
            report.toJson(attachmentUrl: bucket.getPublicUrl(objectPath)),
          );
    } catch (_) {
      try {
        await bucket.remove([objectPath]);
      } catch (e) {
        debugPrint('Could not discard orphan attachment $objectPath: $e');
      }
      rethrow;
    }
  }
}
