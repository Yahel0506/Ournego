import 'package:flutter/material.dart';

import '../../../../core/ournego_text_styles.dart';

class CommunityComingSoonWidget extends StatelessWidget {
  const CommunityComingSoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/images/waiting_telescope.png'),
                  height: 250,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Función de comunidad próximamente disponible!',
                  style: OurnegoTextStyles.header,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hacemos todo lo posible para que puedas conectar con tu comunidad. ¡Mantente atento a las actualizaciones!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
