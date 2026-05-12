import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/nego/nego_paths.dart';

void main() {
  test('eye path matches the expected viewBox bounds', () {
    final path = NegoPaths.eyePath();

    expect(path.getBounds().width, 68);
    expect(path.getBounds().height, 132);
  });

  test('excited and winking cutouts stay within the intended geometry', () {
    final excitedBounds = NegoPaths.excitedCutoutActive().getBounds();
    final winkingBounds = NegoPaths.winkingCutoutActive().getBounds();

    expect(excitedBounds.bottom, 132);
    expect(excitedBounds.width, 68);
    expect(winkingBounds.right, 68);
    expect(winkingBounds.top, 18);
  });
}
