import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';

class BusinessPanelComingSoonWidget extends StatelessWidget {
  const BusinessPanelComingSoonWidget({super.key});

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
                  image: AssetImage('assets/images/waiting_clock.png'),
                  height: 250,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Panel de negocio en camino!',
                  style: OurnegoTextStyles.header,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Estamos trabajando arduamente para traerte esta función. ¡Pronto estará disponible!',
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
