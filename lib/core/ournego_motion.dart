import 'package:flutter/animation.dart';

const Duration kFastDuration = Duration(milliseconds: 120);
const Duration kFastWithPaddingDuration = Duration(milliseconds: 140);
const Duration kStandardDuration = Duration(milliseconds: 220);
const Curve kEaseOutExpo = Cubic(0.16, 1.0, 0.3, 1.0);
const Curve kEaseOutQuart = Curves.easeOutQuart;
const Curve kEaseOutCubic = Curves.easeOutCubic;
const Curve kStandardCurve = Curves.easeInOut;
const Duration kSheetTransitionDuration = Duration(milliseconds: 420);
const Duration kOnboardingPageDuration = Duration(milliseconds: 600);
const Duration kBackgroundDriftDuration = Duration(seconds: 4);

// Lip buttons (playful). kOurnegoSpring overshoots on purpose: never use it
// on flat glass elements.
const Curve kOurnegoSpring = Cubic(0.34, 1.56, 0.64, 1.0);
const Duration kPressDownDuration = Duration(milliseconds: 50);
const Duration kPressReleaseDuration = Duration(milliseconds: 160);
const Duration kBoingDuration = Duration(milliseconds: 340);
const Duration kIconPopDuration = Duration(milliseconds: 450);
const Duration kBurstDuration = Duration(milliseconds: 700);
const Duration kEyesLoaderPeriod = Duration(milliseconds: 720);
const Duration kColorChangeDuration = Duration(milliseconds: 200);

// Flat glass (calm, no overshoot).
const Curve kCalmCurve = Cubic(0.22, 1.0, 0.36, 1.0);
const Duration kGlassPressDuration = Duration(milliseconds: 90);
const Duration kGlassReleaseDuration = Duration(milliseconds: 240);
const Duration kGlassHoverDuration = Duration(milliseconds: 180);
const Duration kListeningHaloPeriod = Duration(milliseconds: 1800);
// Used with kEaseOutExpo.
const Duration kNavIndicatorDuration = Duration(milliseconds: 380);
