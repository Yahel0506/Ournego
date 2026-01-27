import 'package:cloud_firestore/cloud_firestore.dart';

class AppPosition {
  final double latitude;
  final double longitude;
  String? address;
  Timestamp? timestamp;

  AppPosition({
    required this.latitude,
    required this.longitude,
    this.address,
    this.timestamp,
  });
}
