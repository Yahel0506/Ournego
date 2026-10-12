import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/nego/nego_avatar.dart';
import 'package:ournego/shared/widgets/nego/nego_mood.dart';

/// Nego next to a speech bubble, used to explain things in his own voice.
class NegoSpeechBubble extends StatelessWidget {
  const NegoSpeechBubble({
    super.key,
    required this.message,
    this.mood = NegoMood.idle,
    this.avatarSize = 88,
  });

  final String message;
  final NegoMood mood;
  final double avatarSize;

  static const double _tailSize = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = colorScheme.primaryContainer;
    final textColor = colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NegoAvatar(size: avatarSize, mood: mood, interactive: false),
        const SizedBox(width: OurnegoSpacingTokens.md),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -_tailSize / 2 + 1,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: _tailSize,
                      height: _tailSize,
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: OurnegoSpacingTokens.md,
                  vertical: OurnegoSpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
                ),
                child: Text(
                  message,
                  style: OurnegoTextStyles.body.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
