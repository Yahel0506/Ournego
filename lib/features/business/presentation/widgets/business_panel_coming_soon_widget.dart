import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';

class BusinessPanelComingSoonWidget extends StatelessWidget {
  const BusinessPanelComingSoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: AssetImage('assets/images/waiting_clock.png'),
            height: 250,
          ),
          SizedBox(height: 16.0),
          Text(
            '¡Panel de negocio en camino!',
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Text(
            'Estamos trabajando arduamente para traerte esta función. ¡Pronto estará disponible!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 48),
        ],
      ),
    );
  }
}
