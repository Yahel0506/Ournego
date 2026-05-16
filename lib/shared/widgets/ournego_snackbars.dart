import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

class OurnegoSnackbars {
  OurnegoSnackbars._();

  static SnackBar error(BuildContext context, String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      content: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: OurnegoTextStyles.bodyCompact.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static SnackBar info(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OurnegoColorTokens.info.withValues(alpha: 0.12),
      content: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: OurnegoColorTokens.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: OurnegoTextStyles.bodyCompact.copyWith(
                color: OurnegoColorTokens.noche,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static SnackBar success(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OurnegoColorTokens.success.withValues(alpha: 0.16),
      content: Row(
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
                color: OurnegoColorTokens.noche,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static SnackBar warning(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OurnegoColorTokens.warning.withValues(alpha: 0.16),
      content: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: OurnegoColorTokens.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: OurnegoTextStyles.bodyCompact.copyWith(
                color: OurnegoColorTokens.noche,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
