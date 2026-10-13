import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/nego/nego_geometry_state.dart';
import 'package:ournego/shared/widgets/nego/nego_mood.dart';
import 'package:ournego/shared/widgets/nego/nego_tokens.dart';

void main() {
  test('idle uses the base circular geometry', () {
    final geometry = NegoGeometryState.forMood(mood: NegoMood.idle);

    expect(geometry.eyeWidth, NegoTokens.eyeIdleWidth);
    expect(geometry.eyeHeight, NegoTokens.eyeIdleHeight);
    expect(geometry.eyeRadius, NegoTokens.eyeIdleRadius);
    expect(geometry.bodyScale, 1.0);
    expect(geometry.glowOpacity, NegoTokens.glowOpacityIdle);
    expect(geometry.floatDuration, NegoTokens.idleFloatDuration);
  });

  test('excited and winking share the lifted active geometry', () {
    final excited = NegoGeometryState.forMood(mood: NegoMood.excited);
    final winking = NegoGeometryState.forMood(mood: NegoMood.winking);

    expect(excited.eyeWidth, NegoTokens.eyeExcitedWidth);
    expect(excited.eyeGroupYOffset, -10.0);
    expect(excited.floatDuration, NegoTokens.activeFloatDuration);
    expect(winking.eyeWidth, NegoTokens.eyeIdleWidth);
    expect(winking.bodyScale, 1.04);
  });

  test('happy overrides the persistent mood geometry', () {
    final geometry = NegoGeometryState.forMood(mood: NegoMood.happy);

    expect(geometry.eyeWidth, NegoTokens.eyeHappyWidth);
    expect(geometry.eyeHeight, NegoTokens.eyeHappyHeight);
    expect(geometry.eyeRadius, NegoTokens.eyeHappyRadius);
    expect(geometry.glowOpacity, NegoTokens.glowOpacityHappy);
    expect(geometry.glowScale, NegoTokens.glowScaleHappy);
  });
}
