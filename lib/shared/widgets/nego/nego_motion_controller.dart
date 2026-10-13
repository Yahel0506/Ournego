import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'nego_geometry_state.dart';
import 'nego_mood.dart';
import 'nego_motion_values.dart';
import 'nego_tokens.dart';

class NegoMotionController extends ChangeNotifier {
  NegoMotionController({
    required TickerProvider vsync,
    required NegoMood mood,
    required double lookAngle,
    required NegoLookVertical lookVertical,
    required bool interactive,
    bool eyesClosed = false,
    bool floating = true,
  }) : _vsync = vsync,
       _mood = mood,
       _lookAngle = lookAngle,
       _lookVertical = lookVertical,
       _interactive = interactive,
       _eyesClosed = eyesClosed,
       _floating = floating {
    _fromGeometry = _targetGeometry;
    _toGeometry = _targetGeometry;

    _idleController = AnimationController(
      vsync: _vsync,
      duration: _targetGeometry.floatDuration,
    );
    if (_floating) _idleController.repeat();

    _moodTransitionController = AnimationController(
      vsync: _vsync,
      duration: NegoTokens.motionTransition,
    )..addListener(_handleControllerTick);

    _blinkController =
        AnimationController(
            vsync: _vsync,
            duration: const Duration(milliseconds: 180),
          )
          ..addListener(_handleControllerTick)
          ..addStatusListener(_handleBlinkStatus);

    _happyController = AnimationController(
      vsync: _vsync,
      duration: NegoTokens.happyPulseDuration,
    )..addListener(_handleControllerTick);

    _pointerXController = AnimationController.unbounded(vsync: _vsync, value: 0)
      ..addListener(_handleControllerTick);

    _pointerYController = AnimationController.unbounded(vsync: _vsync, value: 0)
      ..addListener(_handleControllerTick);

    _syncBlinkState();
  }

  final TickerProvider _vsync;

  late final AnimationController _idleController;
  late final AnimationController _moodTransitionController;
  late final AnimationController _blinkController;
  late final AnimationController _happyController;
  late final AnimationController _pointerXController;
  late final AnimationController _pointerYController;

  Timer? _blinkTimer;
  Timer? _blinkHoldTimer;
  Timer? _happyTimer;
  bool _tickerModeEnabled = true;
  NegoMood? _temporaryMood;
  bool _isBlinkScaleOverridden = false;
  double _blinkScaleY = 1;
  double _blinkFromScaleY = 1;
  double _blinkToScaleY = 1;
  bool _blinkClosing = false;

  NegoMood _mood;
  double _lookAngle;
  NegoLookVertical _lookVertical;
  bool _interactive;
  bool _eyesClosed;
  bool _floating;

  NegoGeometryState _fromGeometry = NegoGeometryState.forMood(
    mood: NegoMood.idle,
  );
  NegoGeometryState _toGeometry = NegoGeometryState.forMood(
    mood: NegoMood.idle,
  );

  NegoMood get mood => _mood;
  bool get isHappy => activeMood == NegoMood.happy;
  bool get interactive => _interactive;
  bool get eyesClosed => _eyesClosed;
  bool get floating => _floating;
  NegoMood get activeMood => _temporaryMood ?? _mood;

  NegoGeometryState get _targetGeometry =>
      NegoGeometryState.forMood(mood: activeMood);

  NegoGeometryState get geometry => NegoGeometryState.lerp(
    _fromGeometry,
    _toGeometry,
    _moodTransitionController.value,
  );

  NegoMotionValues get motionValues {
    final NegoGeometryState currentGeometry = geometry;
    final double idlePhase = _idleController.value * math.pi * 2;
    final double bodyTranslationY =
        -currentGeometry.floatAmplitude * (1 - math.cos(idlePhase)) / 2;
    final double pointerRotation = _interactive
        ? _pointerXController.value * NegoTokens.bodyRotationRange
        : 0;
    final double lookRotationDegrees = activeMood == NegoMood.looking
        ? _clampedLookAngle()
        : 0;
    final double pointerEyeX = _interactive && activeMood != NegoMood.looking
        ? _pointerXController.value * NegoTokens.eyePointerXRange
        : 0;
    final double pointerEyeY = _interactive
        ? _pointerYController.value * NegoTokens.eyePointerYRange
        : 0;
    final double lookingEyeY = activeMood == NegoMood.looking
        ? _lookingOffsetY()
        : 0;
    final double happyT = Curves.easeInOut.transform(_happyController.value);
    final double happyPulseScale = isHappy
        ? 0.9 + (math.sin(math.pi * happyT) * 0.55)
        : 0.9;
    final double happyPulseOpacity = isHappy ? 0.45 * (1 - happyT) : 0;
    final double happyBodyScale = isHappy
        ? 1 + (math.sin(math.pi * happyT) * 0.08)
        : 1;

    return NegoMotionValues(
      bodyTranslationY: bodyTranslationY,
      bodyRotationDegrees: pointerRotation,
      lookRotationDegrees: lookRotationDegrees,
      eyeOffsetX: pointerEyeX,
      eyeOffsetY: pointerEyeY + lookingEyeY,
      blinkScaleY: _blinkScaleY,
      happyPulseScale: happyPulseScale,
      happyPulseOpacity: happyPulseOpacity,
      happyBodyScale: happyBodyScale,
      happyGlowScale: currentGeometry.glowScale,
    );
  }

  void updateConfiguration({
    required NegoMood mood,
    required double lookAngle,
    required NegoLookVertical lookVertical,
    required bool interactive,
    bool eyesClosed = false,
    bool floating = true,
  }) {
    final bool moodChanged = mood != _mood;
    final bool lookChanged =
        lookAngle != _lookAngle || lookVertical != _lookVertical;
    final bool interactiveChanged = interactive != _interactive;

    _mood = mood;
    _lookAngle = lookAngle;
    _lookVertical = lookVertical;
    _interactive = interactive;
    _eyesClosed = eyesClosed;

    _syncBlinkState();

    if (!_interactive) {
      _pointerXController.value = 0;
      _pointerYController.value = 0;
    }

    if (moodChanged || lookChanged || interactiveChanged) {
      _animateGeometryToTarget();
    }

    final Duration targetDuration = _targetGeometry.floatDuration;
    final bool floatingChanged = floating != _floating;
    _floating = floating;
    if (!_floating) {
      // A still body: no infinite ticker, so pumpAndSettle can finish.
      if (floatingChanged || _idleController.isAnimating) {
        _idleController
          ..stop()
          ..value = 0;
      }
    } else if (floatingChanged || _idleController.duration != targetDuration) {
      _idleController
        ..duration = targetDuration
        ..repeat();
    }

    notifyListeners();
  }

  void setTickerModeEnabled(bool enabled) {
    if (_tickerModeEnabled == enabled) return;
    _tickerModeEnabled = enabled;

    if (!enabled) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _blinkHoldTimer?.cancel();
      _blinkHoldTimer = null;
      return;
    }

    _syncBlinkState();
  }

  void updatePointer(Offset normalized) {
    if (!_interactive) return;

    final double clampedX = normalized.dx.clamp(-1.0, 1.0);
    final double clampedY = normalized.dy.clamp(-1.0, 1.0);

    _pointerXController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 120, damping: 18),
        _pointerXController.value,
        clampedX,
        _pointerXController.velocity,
      ),
    );
    _pointerYController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 120, damping: 18),
        _pointerYController.value,
        clampedY,
        _pointerYController.velocity,
      ),
    );
  }

  /// Shows the temporary happy mood. `force` bypasses [interactive], for
  /// decorative avatars driven by their parent (e.g. a pressed button).
  void triggerHappy({bool force = false}) {
    if (!_interactive && !force) return;

    _temporaryMood = NegoMood.happy;
    _happyController.forward(from: 0);
    _syncBlinkState();
    _animateGeometryToTarget();
    _happyTimer?.cancel();
    _happyTimer = Timer(NegoTokens.happyTemporaryDuration, () {
      _temporaryMood = null;
      _animateGeometryToTarget();
      _syncBlinkState();
      notifyListeners();
    });
    notifyListeners();
  }

  void _syncBlinkState() {
    // Closed eyes hold the same vertical scale the blink uses, without
    // scheduling blinks. This is not a path morph.
    if (_eyesClosed) {
      _cancelBlink();
      _isBlinkScaleOverridden = true;
      _blinkScaleY = NegoTokens.eyesClosedScaleY;
      return;
    }

    // Blink is additive/overlay and must not stop idle motion, but it is
    // disabled entirely while winking (per spec).
    if (activeMood == NegoMood.winking) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _blinkHoldTimer?.cancel();
      _blinkHoldTimer = null;
      _blinkController.stop();
      _isBlinkScaleOverridden = true;
      _blinkScaleY = 1;
      return;
    }

    if (_isBlinkScaleOverridden) {
      _isBlinkScaleOverridden = false;
      _blinkScaleY = 1;
    }
    if (_tickerModeEnabled &&
        _blinkTimer == null &&
        !_blinkController.isAnimating) {
      _scheduleNextBlink();
    }
  }

  void _cancelBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _blinkHoldTimer?.cancel();
    _blinkHoldTimer = null;
    _blinkController.stop();
    _blinkClosing = false;
  }

  void disposeController() {
    _blinkTimer?.cancel();
    _blinkHoldTimer?.cancel();
    _happyTimer?.cancel();
    _idleController.dispose();
    _moodTransitionController.dispose();
    _blinkController.dispose();
    _happyController.dispose();
    _pointerXController.dispose();
    _pointerYController.dispose();
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  void _animateGeometryToTarget() {
    final NegoGeometryState nextGeometry = _targetGeometry;
    _fromGeometry = geometry;
    _toGeometry = nextGeometry;
    _moodTransitionController.forward(from: 0);
  }

  void _scheduleNextBlink() {
    if (!_tickerModeEnabled || _eyesClosed || activeMood == NegoMood.winking) {
      return;
    }

    _blinkTimer?.cancel();
    final int minDelay = NegoTokens.idleBlinkMinDelay.inMilliseconds;
    final int maxDelay = NegoTokens.idleBlinkMaxDelay.inMilliseconds;
    final int delayMs = minDelay + math.Random().nextInt(maxDelay - minDelay);

    _blinkTimer = Timer(Duration(milliseconds: delayMs), () {
      _blinkTimer = null;
      if (_eyesClosed) return;
      if (!_tickerModeEnabled || activeMood == NegoMood.winking) {
        _scheduleNextBlink();
        return;
      }

      _startBlinkClose();
    });
  }

  void _handleBlinkStatus(AnimationStatus status) {
    if (_isBlinkScaleOverridden) return;
    if (status != AnimationStatus.completed) return;

    if (_blinkClosing) {
      _blinkClosing = false;
      _blinkHoldTimer?.cancel();
      _blinkHoldTimer = Timer(NegoTokens.blinkClosedHold, () {
        _blinkHoldTimer = null;
        _startBlinkOpen();
      });
      return;
    }

    _blinkScaleY = 1;
    _scheduleNextBlink();
    notifyListeners();
  }

  void _handleControllerTick() {
    if (_blinkController.isAnimating && !_isBlinkScaleOverridden) {
      final double t = Curves.easeInOut.transform(_blinkController.value);
      _blinkScaleY = ui.lerpDouble(_blinkFromScaleY, _blinkToScaleY, t)!;
    }

    if (_eyesClosed) {
      _blinkScaleY = NegoTokens.eyesClosedScaleY;
    } else if (activeMood == NegoMood.winking) {
      _blinkScaleY = 1;
    }

    notifyListeners();
  }

  void _startBlinkClose() {
    if (_isBlinkScaleOverridden) return;

    _blinkHoldTimer?.cancel();
    _blinkHoldTimer = null;
    _blinkClosing = true;
    _blinkFromScaleY = 1;
    _blinkToScaleY = NegoTokens.blinkScaleY;
    _blinkController.duration = Duration(
      milliseconds: NegoTokens.blinkClosedDurationMs.round(),
    );
    _blinkController.forward(from: 0);
  }

  void _startBlinkOpen() {
    if (_isBlinkScaleOverridden) return;

    _blinkFromScaleY = NegoTokens.blinkScaleY;
    _blinkToScaleY = 1;
    _blinkController.duration = Duration(
      milliseconds: NegoTokens.blinkOpenDurationMs.round(),
    );
    _blinkController.forward(from: 0);
  }

  double _lookingOffsetY() {
    final double lookDirection = _lookVertical == NegoLookVertical.down
        ? 1
        : -1;
    final double lookIntensity = math.max(
      NegoTokens.lookIntensityMin,
      _clampedLookAngle().abs(),
    );
    return lookDirection * lookIntensity * NegoTokens.lookVerticalMultiplier;
  }

  double _clampedLookAngle() {
    return _lookAngle.clamp(NegoTokens.lookAngleMin, NegoTokens.lookAngleMax);
  }
}
