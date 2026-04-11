import 'dart:io';

class FeedbackReport {
  final String message;
  final String model;
  final String os;
  final File attachment;

  const FeedbackReport({
    required this.message,
    required this.model,
    required this.os,
    required this.attachment,
  });
}
