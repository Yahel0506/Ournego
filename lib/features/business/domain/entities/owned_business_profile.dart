import 'package:ournego/features/business/domain/entities/app_schedule.dart';

class OwnedBusinessProfile {
  final String id;
  final String name;
  final String description;
  final int category;
  final String address;
  final String? phoneNumber;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<AppSchedule> hours;

  const OwnedBusinessProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.hours,
  });
}
