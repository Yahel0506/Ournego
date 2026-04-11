import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/features/feedback/data/models/feedback_report_model.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';

void main() {
  group('FeedbackReportModel', () {
    test('fromEntity copies all values', () {
      const message = 'App crash while sending form';
      const model = 'Pixel 7';
      const os = 'Android 15';
      final attachment = File('/tmp/feedback.png');

      final report = FeedbackReport(
        message: message,
        model: model,
        os: os,
        attachment: attachment,
      );

      final result = FeedbackReportModel.fromEntity(report);

      expect(result.message, message);
      expect(result.model, model);
      expect(result.os, os);
      expect(result.attachment.path, attachment.path);
    });

    test('toJson uses provided attachmentUrl', () {
      final model = FeedbackReportModel(
        message: 'msg',
        model: 'device',
        os: 'os',
        attachment: File('/tmp/fallback.png'),
      );

      final json = model.toJson(
        attachmentUrl: 'https://cdn.example.com/feedback.png',
      );

      expect(json['message'], 'msg');
      expect(json['model'], 'device');
      expect(json['os'], 'os');
      expect(json['attachment'], 'https://cdn.example.com/feedback.png');
    });
  });
}
