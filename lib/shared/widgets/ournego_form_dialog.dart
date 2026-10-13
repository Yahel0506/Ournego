import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// Dialog shell for forms (text fields, pickers): same glass look as
/// [OurnegoAlertDialog] but with a widget body, a scrollable content area and
/// its own keyboard avoidance, which a plain centered dialog does not have.
///
/// While [isSaving] is true the primary action shows the loading state and both
/// actions stop responding, so the dialog can stay open until a save finishes.
class OurnegoFormDialog extends StatelessWidget {
  const OurnegoFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.primaryAction,
    this.secondaryAction,
    this.isSaving = false,
    this.maxWidth = 360,
    this.scrollable = true,
  });

  final String title;
  final Widget child;
  final OurnegoDialogAction primaryAction;
  final OurnegoDialogAction? secondaryAction;
  final bool isSaving;
  final double maxWidth;

  /// Wraps [child] in a scroll view. Turn it off when [child] has its own
  /// gestures that would fight the scroll, such as a map.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final primary = primaryAction;
    final secondary = secondaryAction;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(OurnegoSpacingTokens.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              type: MaterialType.transparency,
              child: ContainerTransformDestination(
                child: OurnegoContentContainer(
                  hasBlur: true,
                  borderRadius: OurnegoRadiusTokens.window,
                  customHorizontalPadding: OurnegoSpacingTokens.lg,
                  customVerticalPadding: OurnegoSpacingTokens.lg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: OurnegoTextStyles.title),
                      const SizedBox(height: OurnegoSpacingTokens.md),
                      Flexible(
                        child: scrollable
                            ? SingleChildScrollView(child: child)
                            : child,
                      ),
                      const SizedBox(height: OurnegoSpacingTokens.md),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: 8,
                        overflowSpacing: 8,
                        children: [
                          if (secondary != null)
                            OurnegoButton.text(
                              key: secondary.key,
                              size: OurnegoButtonSize.compact,
                              label: secondary.label,
                              onPressed: isSaving ? null : secondary.onPressed,
                            ),
                          OurnegoButton.primary(
                            key: primary.key,
                            size: OurnegoButtonSize.compact,
                            label: primary.label,
                            status: isSaving
                                ? OurnegoButtonStatus.loading
                                : OurnegoButtonStatus.idle,
                            onPressed: isSaving ? null : primary.onPressed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
