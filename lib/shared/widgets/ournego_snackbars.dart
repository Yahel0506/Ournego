import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class OurnegoSnackbars {
  OurnegoSnackbars._();

  /// Error snackbar. When [actionLabel] and [onAction] are given it shows a
  /// button (e.g. "Reintentar") inside the glass container and stays longer.
  static SnackBar error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final hasAction = actionLabel != null && onAction != null;
    return SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: hasAction
          ? const Duration(seconds: 8)
          : const Duration(seconds: 4),
      content: OurnegoContentContainer(
        hasBlur: true,
        backgroundColor: OurnegoColorTokens.info.withValues(alpha: 0.12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.errorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: 8),
              Builder(
                builder: (innerContext) => OurnegoButton.neutral(
                  key: const ValueKey('snackbarAction'),
                  label: actionLabel,
                  size: OurnegoButtonSize.small,
                  onPressed: () {
                    ScaffoldMessenger.of(innerContext).hideCurrentSnackBar();
                    onAction();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static SnackBar info(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: OurnegoContentContainer(
        hasBlur: true,
        backgroundColor: OurnegoColorTokens.info.withValues(alpha: 0.12),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: OurnegoColorTokens.info),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static SnackBar success(String message) {
    return SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: OurnegoContentContainer(
        hasBlur: true,
        backgroundColor: OurnegoColorTokens.success,
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: OurnegoColorTokens.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static SnackBar warning(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: OurnegoContentContainer(
        hasBlur: true,
        backgroundColor: OurnegoColorTokens.warning,
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: OurnegoColorTokens.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
