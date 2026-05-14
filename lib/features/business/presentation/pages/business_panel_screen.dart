import 'package:flutter/material.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel_dashboard_widget.dart';

class BusinessPanelScreen extends StatelessWidget {
  const BusinessPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BusinessPanelDashboardWidget(
      key: ValueKey('businessDashboardScreen'),
    );
  }
}
