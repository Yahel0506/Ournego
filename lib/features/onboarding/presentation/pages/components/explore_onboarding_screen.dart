import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';

class ExploreOnboardingScreen extends StatelessWidget {
  const ExploreOnboardingScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(
            child: NegoAvatar(
              size: 232,
              mood: NegoMood.idle,
              lookAngle: NegoTokens.lookAngleDefault,
              lookVertical: NegoLookVertical.down,
              interactive: true,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
