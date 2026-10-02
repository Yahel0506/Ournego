import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/feedback/data/models/feedback_report_model.dart';

class FeedbackDatasource {
  final _supabase = Supabase.instance.client;

  Future<void> sendFeedback(FeedbackReportModel report) async {
    final fileName = p.basename(report.attachment.path);

    await _supabase.storage
        .from('feedback_attachments')
        .upload(fileName, report.attachment);

    final attachmentUrl = _supabase.storage
        .from('feedback_attachments')
        .getPublicUrl(fileName);

    await _supabase.from('feedback').insert(
      report.toJson(attachmentUrl: attachmentUrl),
    );
  }
}
