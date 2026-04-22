import 'package:flutter/material.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';

class CommunityComingSoonWidget extends StatelessWidget {
  const CommunityComingSoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: const SizedBox.expand(
          child: InformationCardWidget(
            title: '¡Función de comunidad próximamente disponible!',
            description:
                'Hacemos todo lo posible para que puedas conectar con tu comunidad. ¡Mantente atento a las actualizaciones!',
            imagePath: 'assets/images/waiting_telescope.png',
            contentContainer: false,
          ),
        ),
      ),
    );
  }
}
