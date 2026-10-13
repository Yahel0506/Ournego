import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/motion/motion_window.dart';
import 'package:ournego/core/ournego_motion.dart';

void main() {
  group('seg', () {
    test('is 0 before the window and 1 after it', () {
      expect(seg(0.1, 0.4, 0.75), 0);
      expect(seg(0.9, 0.4, 0.75), 1);
    });

    test('clamps an overshooting or negative p', () {
      expect(seg(1.08, 0.4, 0.75), 1);
      expect(seg(-0.2, 0.4, 0.75), 0);
    });

    test('is linear by default and applies the curve when given one', () {
      expect(seg(0.575, 0.4, 0.75), closeTo(0.5, 1e-9));
      expect(
        seg(0.575, 0.4, 0.75, Curves.easeOut),
        closeTo(Curves.easeOut.transform(0.5), 1e-9),
      );
    });
  });

  group('MotionWindow', () {
    test('shifted moves both ends', () {
      const w = MotionWindow(0.3, 0.7);
      final s = w.shifted(0.06);
      expect(s.start, closeTo(0.36, 1e-9));
      expect(s.end, closeTo(0.76, 1e-9));
    });
  });

  group('presets', () {
    const presets = <String, OurnegoSpringPreset>{
      'dialog': kDialogSpring,
      'popover': kPopoverSpring,
      'bottomSheet': kBottomSheetSpring,
      'floatingSheet': kFloatingSheetSpring,
      'sheetExpand': kSheetExpandSpring,
      'minimize': kMinimizeSpring,
      'searchInPlace': kSearchInPlaceSpring,
      'fullBleed': kFullBleedSpring,
    };

    test('never rebound on close and stay calm on open', () {
      presets.forEach((name, p) {
        expect(p.closeDamping, 1, reason: name);
        expect(p.openDamping, inInclusiveRange(0.85, 1.0), reason: name);
        expect(p.contentEnd, greaterThan(p.contentStart), reason: name);
      });
    });

    test('settle: SpringSimulation reaches rest within a second', () {
      presets.forEach((name, p) {
        final sim = SpringSimulation(
          p.open,
          0,
          1,
          0,
          tolerance: kOurnegoSpringTolerance,
        );
        expect(sim.isDone(1.0), isTrue, reason: name);
      });
    });
  });
}
