import 'package:flutter/material.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel_coming_soon_widget.dart';

class BusinessPanelScreen extends StatelessWidget {
  const BusinessPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('businessDashboardScreen'),
      body: Center(child: BusinessPanelComingSoonWidget()),
    );
  }
}
