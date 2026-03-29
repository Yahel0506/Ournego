import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackDatasource {
  final _supabase = Supabase.instance.client;

  Future<void> sendFeedback({
    required String message,
    required String model,
    required String os,
    required File attachment,
  }) async {
    final fileName = p.basename(attachment.path);

    await _supabase.storage
        .from('feedback_attachments')
        .upload(fileName, attachment);

    final attachmentUrl = _supabase.storage
        .from('feedback_attachments')
        .getPublicUrl(fileName);

    await _supabase.from('feedback').insert({
      'message': message,
      'model': model,
      'os': os,
      'attachment': attachmentUrl,
    });
  }
}
