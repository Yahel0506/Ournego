import 'package:cloud_firestore/cloud_firestore.dart';

class AppPosition {
  final double latitude;
  final double longitude;
  Timestamp? timestamp;

  AppPosition({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });
}
