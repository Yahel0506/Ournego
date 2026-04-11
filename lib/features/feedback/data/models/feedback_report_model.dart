import 'dart:io';

import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';

class FeedbackReportModel extends FeedbackReport {
  const FeedbackReportModel({
    required super.message,
    required super.model,
    required super.os,
    required super.attachment,
  });

  factory FeedbackReportModel.fromEntity(FeedbackReport report) {
    return FeedbackReportModel(
      message: report.message,
      model: report.model,
      os: report.os,
      attachment: report.attachment,
    );
  }

  factory FeedbackReportModel.fromJson(Map<String, dynamic> json) {
    return FeedbackReportModel(
      message: json['message'] as String,
      model: json['model'] as String,
      os: json['os'] as String,
      attachment: File(json['attachment'] as String),
    );
  }

  Map<String, dynamic> toJson({String? attachmentUrl}) {
    return {
      'message': message,
      'model': model,
      'os': os,
      'attachment': attachmentUrl ?? attachment.path,
    };
  }
}
