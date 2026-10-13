import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

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

// Container transform (windows that grow out of the element that opened them).
// Calm character: opening springs sit at zeta 0.85-0.90 and closing springs
// are critically damped, so flat glass never visibly overshoots.

/// Spring and window parameters of one container-transform preset.
///
/// All springs have mass 1. [contentStart] and [contentEnd] are the window of
/// the progress clock `p` in which the destination content fades in. With a
/// blur ([maxItemBlur] > 0) the content arrives fully blurred and stays so
/// while the container travels; the blur clears over [blurClearStart] to 1 and
/// is gone exactly when the container's animation ends.
@immutable
class OurnegoSpringPreset {
  const OurnegoSpringPreset({
    required this.openStiffness,
    required this.openDamping,
    required this.closeStiffness,
    required this.closeDamping,
    required this.contentStart,
    required this.contentEnd,
    this.stagger = 0,
    this.scrimAlpha = 0,
    this.maxItemBlur = 0,
    this.blurClearStart = 0.65,
    this.verticalPath,
  });

  final double openStiffness;

  /// Damping ratio (zeta) of the opening spring.
  final double openDamping;
  final double closeStiffness;

  /// Damping ratio (zeta) of the closing spring. Always 1: no rebound on close.
  final double closeDamping;
  final double contentStart;
  final double contentEnd;

  /// Extra delay of each item, in units of `p`. Applied only while opening.
  final double stagger;
  final double scrimAlpha;

  /// Blur sigma in dp of the content while it travels. 0 means no blur (level C).
  /// It is constant (static) until [blurClearStart].
  final double maxItemBlur;

  /// Where in `p` the blur starts to clear, linearly, reaching 0 at `p = 1`.
  /// Items also start to respond to touches here.
  final double blurClearStart;

  /// Shapes the container's vertical travel over the whole path, so the window
  /// leans into its destination, passes it slightly and settles back, while the
  /// horizontal position and the size follow the plain route. Null is a straight
  /// path. The same curve is used to open and to close, so reversing mid-way
  /// never jumps.
  final Curve? verticalPath;

  SpringDescription get open => SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: openStiffness,
    ratio: openDamping,
  );

  SpringDescription get close => SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: closeStiffness,
    ratio: closeDamping,
  );

  OurnegoSpringPreset copyWith({
    double? scrimAlpha,
    double? maxItemBlur,
    Curve? verticalPath,
  }) {
    return OurnegoSpringPreset(
      openStiffness: openStiffness,
      openDamping: openDamping,
      closeStiffness: closeStiffness,
      closeDamping: closeDamping,
      contentStart: contentStart,
      contentEnd: contentEnd,
      stagger: stagger,
      scrimAlpha: scrimAlpha ?? this.scrimAlpha,
      maxItemBlur: maxItemBlur ?? this.maxItemBlur,
      blurClearStart: blurClearStart,
      verticalPath: verticalPath ?? this.verticalPath,
    );
  }
}

/// Settling tolerance of every container-transform spring. Without it a spring
/// never reports `isDone` and `pumpAndSettle` would not finish.
const Tolerance kOurnegoSpringTolerance = Tolerance(
  distance: 0.001,
  velocity: 0.01,
);

/// The vertical path of a window: it leads the horizontal one by up to ~20 % of
/// the travel, passes its destination by about 3.5 % at 90 % of the way and
/// settles back with a gentle slope. One smooth curve, no localized kick.
const Curve kWindowVerticalPath = Cubic(0.5, 0.2, 0.7, 1.25);

/// Menu and dialog centered on the screen. Scrim 0.30 is for the account menu;
/// regular dialogs use [kDialogScrimAlpha].
const OurnegoSpringPreset kDialogSpring = OurnegoSpringPreset(
  openStiffness: 170,
  openDamping: 0.9,
  closeStiffness: 185,
  closeDamping: 1,
  contentStart: 0.05,
  contentEnd: 0.30,
  scrimAlpha: 0.30,
  maxItemBlur: 12,
  blurClearStart: 0.62,
  verticalPath: kWindowVerticalPath,
);
const double kDialogScrimAlpha = 0.50;

/// Small anchored popover: chips, map credits, contact notice. No scrim.
const OurnegoSpringPreset kPopoverSpring = OurnegoSpringPreset(
  openStiffness: 500,
  openDamping: 0.90,
  closeStiffness: 600,
  closeDamping: 1,
  contentStart: 0.30,
  contentEnd: 0.65,
);

/// Bottom sheets (location access, zone picker).
const OurnegoSpringPreset kBottomSheetSpring = OurnegoSpringPreset(
  openStiffness: 300,
  openDamping: 0.90,
  closeStiffness: 400,
  closeDamping: 1,
  contentStart: 0.25,
  contentEnd: 0.65,
  scrimAlpha: 0.40,
);

/// Marker or result row to collapsed floating sheet.
const OurnegoSpringPreset kFloatingSheetSpring = OurnegoSpringPreset(
  openStiffness: 300,
  openDamping: 0.90,
  closeStiffness: 400,
  closeDamping: 1,
  contentStart: 0.25,
  contentEnd: 0.65,
);

/// Collapsed to expanded floating sheet; tied to the drag gesture.
const OurnegoSpringPreset kSheetExpandSpring = OurnegoSpringPreset(
  openStiffness: 380,
  openDamping: 0.90,
  closeStiffness: 380,
  closeDamping: 1,
  contentStart: 0.35,
  contentEnd: 0.75,
  scrimAlpha: 0.40,
);
const double kComparisonScrimAlpha = 0.50;

/// Floating sheet to the 48x48 icon of the minimized stack, and back.
const OurnegoSpringPreset kMinimizeSpring = OurnegoSpringPreset(
  openStiffness: 380,
  openDamping: 0.90,
  closeStiffness: 450,
  closeDamping: 1,
  contentStart: 0.60,
  contentEnd: 1.0,
);

/// Search bar growing into the results panel, in place.
const OurnegoSpringPreset kSearchInPlaceSpring = OurnegoSpringPreset(
  openStiffness: 450,
  openDamping: 0.88,
  closeStiffness: 550,
  closeDamping: 1,
  contentStart: 0.35,
  contentEnd: 0.70,
  stagger: 0.04,
);

/// Card to full-screen detail (router pages).
const OurnegoSpringPreset kFullBleedSpring = OurnegoSpringPreset(
  openStiffness: 300,
  openDamping: 1,
  closeStiffness: 400,
  closeDamping: 1,
  contentStart: 0.25,
  contentEnd: 0.65,
);

/// Vertical travel in dp of destination content while it fades in.
const double kWindowContentOffset = 8;

/// Duration of the reduced-motion fade (level R).
const Duration kReducedMotionFadeDuration = kFastDuration;
