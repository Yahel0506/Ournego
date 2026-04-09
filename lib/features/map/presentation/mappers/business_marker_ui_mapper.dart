import 'package:flutter/material.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/models/business_marker_ui_model.dart';

class BusinessMarkerUiMapper {
  const BusinessMarkerUiMapper();

  BusinessMarkerUiModel call(Business business) {
    final BusinessType type = business.type;

    switch (type) {
      case BusinessType.constructionAndHome:
        return const BusinessMarkerUiModel(
          icon: Icons.construction_rounded,
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Color.fromARGB(255, 65, 27, 16),
        );
      case BusinessType.drinkAndEat:
        return const BusinessMarkerUiModel(
          icon: Icons.restaurant_rounded,
          backgroundColor: Colors.red,
          foregroundColor: Color.fromARGB(255, 139, 0, 0),
        );
      case BusinessType.shop:
        return const BusinessMarkerUiModel(
          icon: Icons.shopping_bag_rounded,
          backgroundColor: Colors.blue,
          foregroundColor: Color.fromARGB(255, 13, 71, 161),
        );
      case BusinessType.personalService:
        return const BusinessMarkerUiModel(
          icon: Icons.person_rounded,
          backgroundColor: Colors.purple,
          foregroundColor: Color.fromARGB(255, 75, 0, 130),
        );
      case BusinessType.professionalService:
        return const BusinessMarkerUiModel(
          icon: Icons.business_rounded,
          backgroundColor: Colors.indigo,
          foregroundColor: Color.fromARGB(255, 26, 35, 126),
        );
      case BusinessType.healthAndWellness:
        return const BusinessMarkerUiModel(
          icon: Icons.health_and_safety_rounded,
          backgroundColor: Colors.green,
          foregroundColor: Color.fromARGB(255, 27, 94, 32),
        );
      case BusinessType.education:
        return const BusinessMarkerUiModel(
          icon: Icons.school_rounded,
          backgroundColor: Colors.amber,
          foregroundColor: Color.fromARGB(255, 120, 81, 0),
        );
      case BusinessType.transportation:
        return const BusinessMarkerUiModel(
          icon: Icons.directions_car_rounded,
          backgroundColor: Colors.cyan,
          foregroundColor: Color.fromARGB(255, 0, 77, 64),
        );
      case BusinessType.entertainment:
        return const BusinessMarkerUiModel(
          icon: Icons.theaters_rounded,
          backgroundColor: Colors.pink,
          foregroundColor: Color.fromARGB(255, 136, 14, 79),
        );
      case BusinessType.technology:
        return const BusinessMarkerUiModel(
          icon: Icons.computer_rounded,
          backgroundColor: Colors.teal,
          foregroundColor: Color.fromARGB(255, 0, 77, 64),
        );
      case BusinessType.informalBusiness:
        return const BusinessMarkerUiModel(
          icon: Icons.handshake_rounded,
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        );
      case BusinessType.mixed:
        return const BusinessMarkerUiModel(
          icon: Icons.category_rounded,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
        );
      case BusinessType.unknown:
        return const BusinessMarkerUiModel(
          icon: Icons.help_rounded,
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        );
    }
  }
}
