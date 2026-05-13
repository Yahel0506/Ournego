import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/onboarding/presentation/onboarding_flow_state.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/onboarding_responsive_layout.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topGap = (screenHeight * 0.08).clamp(32.0, 64.0).toDouble();
    final cardsGap = (screenHeight * 0.06).clamp(28.0, 48.0).toDouble();

    return OnboardingResponsiveLayout(
      padding: const EdgeInsets.all(28),
      scrollBelowHeight: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: topGap),
          Text(
            title,
            style: OurnegoTextStyles.onboardingHeader,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: cardsGap),
          _RoleOptionCard(
            key: const ValueKey('onboardingRoleDiscoverButton'),
            title: 'Descubrir',
            description: 'Explora lugares cerca de ti.',
            icon: Icons.person_rounded,
            semanticsLabel: 'Usar Ournego para descubrir lugares',
            onTap: () => onRoleSelected(OnboardingUserRole.discover),
          ),
          const SizedBox(height: 12),
          _RoleOptionCard(
            key: const ValueKey('onboardingRoleBusinessButton'),
            title: 'Tengo un negocio',
            description: 'Haz que más personas te encuentren.',
            icon: Icons.store_rounded,
            semanticsLabel: 'Usar Ournego para mi negocio',
            iconFirst: true,
            onTap: () => onRoleSelected(OnboardingUserRole.business),
          ),
        ],
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
    this.iconFirst = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;
  final bool iconFirst;

  @override
  Widget build(BuildContext context) {
    final iconRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72),
        const Spacer(),
        const Icon(Icons.arrow_forward_rounded, size: 72),
      ],
    );

    final textContent = [
      Text(title, style: OurnegoTextStyles.header, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        description,
        style: OurnegoTextStyles.body,
        textAlign: TextAlign.center,
      ),
    ];

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            width: double.infinity,
            child: OurnegoContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (iconFirst) ...[
                    const SizedBox(height: 12),
                    iconRow,
                    ...textContent,
                  ] else ...[
                    ...textContent,
                    const SizedBox(height: 12),
                    iconRow,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
