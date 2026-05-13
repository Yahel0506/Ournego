import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

enum OnboardingUserRole { discover, business }

class RoleSelectionOnboardingScreen extends StatelessWidget {
  const RoleSelectionOnboardingScreen({
    super.key,
    required this.title,
    required this.onRoleSelected,
  });

  final String title;
  final ValueChanged<OnboardingUserRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 64),
          Text(
            title,
            style: OurnegoTextStyles.onboardingHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => onRoleSelected(OnboardingUserRole.discover),
            child: SizedBox(
              width: double.infinity,
              child: OurnegoContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'Descubrir',
                      style: OurnegoTextStyles.header,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Explora lugares cerca de ti.',
                      style: OurnegoTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded, size: 72),
                        Spacer(),
                        Icon(Icons.arrow_forward_rounded, size: 72),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => onRoleSelected(OnboardingUserRole.business),
            child: SizedBox(
              width: double.infinity,
              child: OurnegoContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_rounded, size: 72),
                        Spacer(),
                        Icon(Icons.arrow_forward_rounded, size: 72),
                      ],
                    ),
                    Text(
                      'Tengo un negocio',
                      style: OurnegoTextStyles.header,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Haz que más personas te encuentren.',
                      style: OurnegoTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
