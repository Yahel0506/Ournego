import 'package:flutter/material.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';

class BusinessPanelComingSoonWidget extends StatelessWidget {
  const BusinessPanelComingSoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: const SizedBox.expand(
          child: InformationCardWidget(
            title: '¡Panel de negocio en camino!',
            description:
                'Estamos trabajando arduamente para traerte esta función. ¡Pronto estará disponible!',
            imagePath: 'assets/images/waiting_clock.png',
          ),
        ),
      ),
    );
  }
}
