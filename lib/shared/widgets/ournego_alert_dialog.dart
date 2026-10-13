import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';

/// One action of [OurnegoAlertDialog].
@immutable
class OurnegoDialogAction {
  const OurnegoDialogAction({
    required this.label,
    required this.onPressed,
    this.key,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Key? key;

  /// Renders the primary action with the destructive tone.
  final bool isDestructive;
}

class OurnegoAlertDialog extends StatelessWidget {
  const OurnegoAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final String content;

  /// The real action, rendered as a primary (or destructive) button.
  final OurnegoDialogAction primaryAction;

  /// Usually "Cancelar", rendered as a text button before the primary one.
  final OurnegoDialogAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final primary = primaryAction;
    final secondary = secondaryAction;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
        child: Material(
          type: MaterialType.transparency,
          // The same padding as the options menu: 12 of surface plus 8 of its
          // own gives the text a 20 dp margin.
          child: OurnegoDialogSurface(
            customHorizontalPadding: OurnegoSpacingTokens.sm,
            customVerticalPadding: OurnegoSpacingTokens.md,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OurnegoSpacingTokens.xs,
                  ),
                  child: Text(title, style: OurnegoTextStyles.title),
                ),
                const SizedBox(height: OurnegoSpacingTokens.sm),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OurnegoSpacingTokens.xs,
                    ),
                    child: Text(content, style: OurnegoTextStyles.bodyCompact),
                  ),
                ),
                const SizedBox(height: OurnegoSpacingTokens.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OurnegoSpacingTokens.xs,
                  ),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: [
                      if (secondary != null)
                        OurnegoButton.text(
                          key: secondary.key,
                          size: OurnegoButtonSize.compact,
                          label: secondary.label,
                          onPressed: secondary.onPressed,
                        ),
                      primary.isDestructive
                          ? OurnegoButton.destructive(
                              key: primary.key,
                              size: OurnegoButtonSize.compact,
                              label: primary.label,
                              onPressed: primary.onPressed,
                            )
                          : OurnegoButton.primary(
                              key: primary.key,
                              size: OurnegoButtonSize.compact,
                              label: primary.label,
                              onPressed: primary.onPressed,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
