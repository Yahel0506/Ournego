import 'package:flutter/material.dart';

import '../../../../core/ournego_text_styles.dart';

class CommunityComingSoonWidget extends StatelessWidget {
  const CommunityComingSoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: AssetImage('assets/images/waiting_telescope.png'),
            height: 250,
          ),
          SizedBox(height: 16.0),
          Text(
            '¡Función de comunidad próximamente disponible!',
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Text(
            'Hacemos todo lo posible para que puedas conectar con tu comunidad. ¡Mantente atento a las actualizaciones!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 48),
        ],
      ),
    );
  }
}
