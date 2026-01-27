import 'package:flutter/material.dart';

class AppSchedule {
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  AppSchedule({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
  });
}
