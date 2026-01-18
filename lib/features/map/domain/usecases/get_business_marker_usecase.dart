import 'package:flutter/material.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_marker.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';

class GetBusinessMarkerUsecase {
  final Business business;

  GetBusinessMarkerUsecase({required this.business});

  BusinessMarker call() {
    BusinessType type = business.type;
    switch (type) {
      case BusinessType.constructionAndHome:
        return BusinessMarker(
          icon: Icons.construction_rounded,
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Color.fromARGB(255, 65, 27, 16),
        );
      case BusinessType.drinkAndEat:
        return BusinessMarker(
          icon: Icons.restaurant_rounded,
          backgroundColor: Colors.red,
          foregroundColor: Color.fromARGB(255, 139, 0, 0),
        );
      case BusinessType.shop:
        return BusinessMarker(
          icon: Icons.shopping_bag_rounded,
          backgroundColor: Colors.blue,
          foregroundColor: Color.fromARGB(255, 13, 71, 161),
        );
      case BusinessType.personalService:
        return BusinessMarker(
          icon: Icons.person_rounded,
          backgroundColor: Colors.purple,
          foregroundColor: Color.fromARGB(255, 75, 0, 130),
        );
      case BusinessType.professionalService:
        return BusinessMarker(
          icon: Icons.business_rounded,
          backgroundColor: Colors.indigo,
          foregroundColor: Color.fromARGB(255, 26, 35, 126),
        );
      case BusinessType.healthAndWellness:
        return BusinessMarker(
          icon: Icons.health_and_safety_rounded,
          backgroundColor: Colors.green,
          foregroundColor: Color.fromARGB(255, 27, 94, 32),
        );
      case BusinessType.education:
        return BusinessMarker(
          icon: Icons.school_rounded,
          backgroundColor: Colors.amber,
          foregroundColor: Color.fromARGB(255, 120, 81, 0),
        );
      case BusinessType.transportation:
        return BusinessMarker(
          icon: Icons.directions_car_rounded,
          backgroundColor: Colors.cyan,
          foregroundColor: Color.fromARGB(255, 0, 77, 64),
        );
      case BusinessType.entertainment:
        return BusinessMarker(
          icon: Icons.theaters_rounded,
          backgroundColor: Colors.pink,
          foregroundColor: Color.fromARGB(255, 136, 14, 79),
        );
      case BusinessType.technology:
        return BusinessMarker(
          icon: Icons.computer_rounded,
          backgroundColor: Colors.teal,
          foregroundColor: Color.fromARGB(255, 0, 77, 64),
        );
      case BusinessType.informalBusiness:
        return BusinessMarker(
          icon: Icons.handshake_rounded,
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        );
      case BusinessType.mixed:
        return BusinessMarker(
          icon: Icons.category_rounded,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
        );
      case BusinessType.unknown:
        return BusinessMarker(
          icon: Icons.help_rounded,
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        );
    }
  }
}
