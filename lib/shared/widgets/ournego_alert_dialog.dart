import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

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
    this.primaryAction,
    this.secondaryAction,
    @Deprecated('Use primaryAction') this.actionLabel = 'OK',
    @Deprecated('Use primaryAction') this.onAction,
    @Deprecated('Use secondaryAction') this.trailingActions = const [],
  }) : assert(primaryAction != null || onAction != null);

  final String title;
  final String content;

  /// The real action, rendered as a primary (or destructive) button.
  final OurnegoDialogAction? primaryAction;

  /// Usually "Cancelar", rendered as a text button before the primary one.
  final OurnegoDialogAction? secondaryAction;

  @Deprecated('Use primaryAction')
  final String actionLabel;
  @Deprecated('Use primaryAction')
  final VoidCallback? onAction;
  @Deprecated('Use secondaryAction')
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use_from_same_package
    final legacyAction = onAction;
    final primary =
        primaryAction ??
        OurnegoDialogAction(
          // ignore: deprecated_member_use_from_same_package
          label: actionLabel,
          onPressed: legacyAction!,
        );
    final secondary = secondaryAction;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
        child: OurnegoContentContainer(
          customVerticalPadding: 0,
          customHorizontalPadding: 0,
          hasBlur: true,
          borderRadius: OurnegoRadiusTokens.sheet,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            title: Text(title, style: OurnegoTextStyles.title),
            content: Text(content, style: OurnegoTextStyles.bodyCompact),
            actions: [
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
                  // ignore: deprecated_member_use_from_same_package
                  ...trailingActions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
