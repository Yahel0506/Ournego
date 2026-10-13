import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/shared/widgets/buttons/nego_eyes_loader.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';

/// Core of every lip button (spec §5): states, flat lip, press, boing,
/// focus ring, keyboard activation, semantics and the 48×48 tap target.
///
/// The lip is a solid block under the face, never a blurred shadow.
class OurnegoPressable extends StatefulWidget {
  const OurnegoPressable({
    super.key,
    required this.onPressed,
    required this.colors,
    required this.faceHeight,
    required this.lipDepth,
    required this.borderRadius,
    required this.child,
    this.width,
    this.minWidth = 0,
    this.minFaceHeight = 0,
    this.padding = EdgeInsets.zero,
    this.borderWidth = OurnegoComponentMetrics.borderWidth,
    this.isLoading = false,
    this.loadingChild,
    this.isGhost = false,
    this.locked = false,
    this.semanticLabel,
    this.tooltip,
    this.toggled,
    this.enableBoing = true,
    this.focusNode,
    this.autofocus = false,
    this.onHoverChanged,
    this.onPressedChanged,
    this.forcePressed = false,
  });

  /// Null means disabled.
  final VoidCallback? onPressed;

  /// Colors already resolved for the tone and brightness. Disabled colors
  /// are applied here when [onPressed] is null.
  final OurnegoButtonColors colors;

  /// Face height; null means intrinsic (tiles).
  final double? faceHeight;

  /// 0 for ghost.
  final double lipDepth;
  final BorderRadius borderRadius;
  final Widget child;

  /// Null means intrinsic; `double.infinity` means expanded.
  final double? width;
  final double minWidth;

  /// Minimum face height when [faceHeight] is null.
  final double minFaceHeight;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final bool isLoading;

  /// Defaults to a [NegoEyesLoader] in the ink color.
  final Widget? loadingChild;
  final bool isGhost;

  /// Ignores input without looking disabled (e.g. the success state).
  final bool locked;
  final String? semanticLabel;
  final String? tooltip;
  final bool? toggled;
  final bool enableBoing;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onPressedChanged;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  State<OurnegoPressable> createState() => _OurnegoPressableState();
}

/// Key of the animated face, used by tests to read its transform.
const ValueKey<String> ournegoPressableFaceKey = ValueKey<String>(
  'ournegoPressableFace',
);

class _OurnegoPressableState extends State<OurnegoPressable>
    with TickerProviderStateMixin {
  // Ghost press scale (spec §3.6).
  static const double _ghostPressedScale = 0.94;

  late final AnimationController _offset;
  late final AnimationController _boing;

  // Offset animation: dy for lip buttons, scale for ghost.
  double _from = 0;
  double _to = 0;
  Curve _curve = Curves.linear;

  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;
  bool get _interactive => _enabled && !widget.isLoading && !widget.locked;
  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  double get _rest => widget.isGhost ? 1 : 0;

  double get _current {
    final t = _offset.value;
    return lerpDouble(_from, _to, _curve.transform(t))!;
  }

  @override
  void initState() {
    super.initState();
    _offset = AnimationController(vsync: this, value: 1);
    _boing = AnimationController(vsync: this, duration: kBoingDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _jumpTo(_releaseTarget);
          _boing.value = 0;
        }
      });
    _from = _to = widget.forcePressed ? _pressedTarget : _rest;
  }

  @override
  void didUpdateWidget(covariant OurnegoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forcePressed != oldWidget.forcePressed) {
      _jumpTo(widget.forcePressed ? _pressedTarget : _rest);
    }
    if (!_interactive && (_pressed || _hovered)) {
      _pressed = false;
      _hovered = false;
      _boing.stop();
      _boing.value = 0;
      _jumpTo(_rest);
    }
  }

  @override
  void dispose() {
    _offset.dispose();
    _boing.dispose();
    super.dispose();
  }

  double get _pressedTarget =>
      widget.isGhost ? _ghostPressedScale : widget.lipDepth;

  double get _releaseTarget {
    if (widget.forcePressed) return _pressedTarget;
    if (widget.isGhost) return 1;
    return _hovered ? -1 : 0;
  }

  void _jumpTo(double value) {
    _from = value;
    _to = value;
    _offset.value = 1;
  }

  void _animateTo(double target, Duration duration, Curve curve) {
    _boing.stop();
    _boing.value = 0;
    _from = _current;
    _to = target;
    _curve = curve;
    _offset
      ..duration = duration
      ..forward(from: 0);
  }

  Curve get _springOrEase => _reducedMotion ? Curves.easeOut : kOurnegoSpring;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    widget.onHoverChanged?.call(value);
    if (_pressed || widget.forcePressed || widget.isGhost) return;
    if (!_interactive) return;
    _animateTo(value ? -1 : 0, kPressReleaseDuration, _springOrEase);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _handleTapDown(TapDownDetails? _) {
    if (!_interactive) return;
    setState(() => _pressed = true);
    widget.onPressedChanged?.call(true);
    if (widget.forcePressed) return;
    _animateTo(_pressedTarget, kPressDownDuration, Curves.linear);
  }

  void _release({required bool allowBoing}) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onPressedChanged?.call(false);
    if (widget.forcePressed) return;

    final canBoing =
        allowBoing &&
        widget.enableBoing &&
        !widget.isGhost &&
        widget.lipDepth > 0 &&
        !_reducedMotion;
    if (canBoing) {
      _offset.stop();
      _boing.forward(from: 0);
      return;
    }
    _animateTo(_releaseTarget, kPressReleaseDuration, _springOrEase);
  }

  void _handleTapUp(TapUpDetails? _) => _release(allowBoing: true);

  void _handleTapCancel() => _release(allowBoing: false);

  void _handleTap() {
    if (!_interactive) return;
    widget.onPressed?.call();
  }

  Future<void> _activateFromKeyboard() async {
    if (!_interactive) return;
    _handleTapDown(null);
    await Future<void>.delayed(kPressDownDuration);
    if (!mounted) return;
    _handleTapUp(null);
    _handleTap();
  }

  // Boing keyframes (spec §3.6): A -> B -> C, each leg with kOurnegoSpring.
  ({double dy, double sx, double sy}) _boingFrame(double t) {
    final lip = widget.lipDepth;
    const b = (dy: -2.0, sx: 0.97, sy: 1.04);
    final target = _releaseTarget;
    if (t <= 0.5) {
      final u = kOurnegoSpring.transform(t / 0.5);
      return (
        dy: lerpDouble(lip, b.dy, u)!,
        sx: lerpDouble(1.04, b.sx, u)!,
        sy: lerpDouble(0.92, b.sy, u)!,
      );
    }
    final u = kOurnegoSpring.transform((t - 0.5) / 0.5);
    return (
      dy: lerpDouble(b.dy, target, u)!,
      sx: lerpDouble(b.sx, 1, u)!,
      sy: lerpDouble(b.sy, 1, u)!,
    );
  }

  OurnegoButtonColors _resolveColors(ColorScheme scheme) {
    if (!_enabled) {
      return OurnegoButtonPalette.disabled(scheme, ghost: widget.isGhost);
    }
    if (widget.isGhost) {
      final showOverlay =
          (_hovered || _pressed || widget.forcePressed) && !widget.isLoading;
      return widget.colors.copyWith(
        face: showOverlay
            ? OurnegoButtonPalette.ghostOverlay(scheme)
            : const Color(0x00000000),
      );
    }
    return widget.colors;
  }

  MouseCursor get _cursor {
    if (!_enabled) return SystemMouseCursors.forbidden;
    if (widget.isLoading) return SystemMouseCursors.progress;
    return SystemMouseCursors.click;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lip = widget.isGhost ? 0.0 : widget.lipDepth;
    final screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 4096;

    final Widget pressable = TweenAnimationBuilder<OurnegoButtonColors>(
      tween: _ButtonColorsTween(end: _resolveColors(scheme)),
      duration: kColorChangeDuration,
      builder: (context, colors, _) => _buildVisual(context, colors, lip),
    );

    Widget result = FocusableActionDetector(
      enabled: _interactive,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _cursor,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activateFromKeyboard();
            return null;
          },
        ),
      },
      onShowHoverHighlight: _setHovered,
      onShowFocusHighlight: _setFocused,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The tap action is exposed by the Semantics node below.
        excludeFromSemantics: true,
        onTapDown: _interactive ? _handleTapDown : null,
        onTapUp: _interactive ? _handleTapUp : null,
        onTapCancel: _interactive ? _handleTapCancel : null,
        onTap: _interactive ? _handleTap : null,
        // Caps the intrinsic width so flexible labels can ellipsize even
        // when the parent gives unbounded width (e.g. inside a Row).
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            maxWidth: math.max(widget.minWidth, screenWidth),
          ),
          child: SizedBox(width: widget.width, child: pressable),
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }

    // The tap target must be the outermost render box: any ancestor of the
    // same size would reject hits outside the visible face.
    return OurnegoMinTapTarget(
      child: Semantics(
        container: true,
        button: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        toggled: widget.toggled,
        liveRegion: widget.isLoading,
        focusable: _interactive ? true : null,
        focused: _interactive ? _focused : null,
        excludeSemantics: widget.semanticLabel != null,
        onTap: _interactive ? _handleTap : null,
        child: result,
      ),
    );
  }

  Widget _buildVisual(
    BuildContext context,
    OurnegoButtonColors colors,
    double lip,
  ) {
    final radius = widget.borderRadius;
    final ringOffset =
        OurnegoComponentMetrics.focusRingWidth +
        OurnegoComponentMetrics.focusRingGap;

    Widget content = widget.child;
    if (widget.isLoading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: widget.child,
          ),
          Positioned.fill(
            child: Center(
              child: widget.loadingChild ?? NegoEyesLoader(color: colors.ink),
            ),
          ),
        ],
      );
    }

    Widget face = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.face,
        borderRadius: radius,
        border: Border.all(color: colors.border, width: widget.borderWidth),
      ),
      child: Padding(
        padding: widget.padding,
        child: IconTheme.merge(
          data: IconThemeData(color: colors.ink),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.ink),
            child: Center(widthFactor: 1, heightFactor: 1, child: content),
          ),
        ),
      ),
    );
    face = widget.faceHeight != null
        ? SizedBox(height: widget.faceHeight, child: face)
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minFaceHeight),
            child: face,
          );

    final animatedFace = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_offset, _boing]),
        child: face,
        builder: (context, child) {
          var dy = 0.0;
          var sx = 1.0;
          var sy = 1.0;
          if (_boing.isAnimating) {
            final frame = _boingFrame(_boing.value);
            dy = frame.dy;
            sx = frame.sx;
            sy = frame.sy;
          } else if (widget.isGhost) {
            sx = sy = _current;
          } else {
            dy = _current;
          }
          return Transform(
            key: ournegoPressableFaceKey,
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(0, dy, 0, 1)
              ..scaleByDouble(sx, sy, 1, 1),
            child: child,
          );
        },
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      // The face takes the parent constraints, so expanded and minWidth
      // buttons stretch the face, not only the lip.
      fit: StackFit.passthrough,
      children: [
        if (lip > 0)
          Positioned(
            left: 0,
            right: 0,
            top: lip,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.lip,
                borderRadius: radius,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: lip),
          child: animatedFace,
        ),
        if (_focused && _interactive)
          Positioned(
            left: -ringOffset,
            top: -ringOffset,
            right: -ringOffset,
            bottom: lip - ringOffset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _inflate(radius, ringOffset),
                  border: Border.all(
                    color: OurnegoButtonPalette.focusRing(
                      Theme.of(context).colorScheme,
                    ),
                    width: OurnegoComponentMetrics.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

BorderRadius _inflate(BorderRadius radius, double by) {
  Radius grow(Radius r) => Radius.elliptical(r.x + by, r.y + by);
  return BorderRadius.only(
    topLeft: grow(radius.topLeft),
    topRight: grow(radius.topRight),
    bottomLeft: grow(radius.bottomLeft),
    bottomRight: grow(radius.bottomRight),
  );
}

class _ButtonColorsTween extends Tween<OurnegoButtonColors> {
  _ButtonColorsTween({required OurnegoButtonColors end})
    : super(begin: end, end: end);

  @override
  OurnegoButtonColors lerp(double t) =>
      OurnegoButtonColors.lerp(begin!, end!, t);
}

/// Extends the hit area of its child to at least 48×48, centered, without
/// changing its layout size (spec §5.6). Taps in the extra area are forwarded
/// to the child's center. Wrappers that add a render box around a pressable
/// (e.g. `OurnegoBurst`) must wrap themselves in another one.
class OurnegoMinTapTarget extends SingleChildRenderObjectWidget {
  const OurnegoMinTapTarget({
    super.key,
    super.child,
    this.minSize = OurnegoComponentMetrics.minTapTarget,
  });

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTapTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderMinTapTarget).minSize = minSize;
  }
}

class _RenderMinTapTarget extends RenderProxyBox {
  _RenderMinTapTarget(this.minSize);

  double minSize;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null) return false;
    final area = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.max(size.width, minSize),
      height: math.max(size.height, minSize),
    );
    if (!area.contains(position)) return false;
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child.hitTest(result, position: center),
    );
  }
}

/// Hover motion of a button icon (spec §3.6): `nudge` moves it 3 px to the
/// right, `wiggle` rotates -10° and scales 1.12. Mouse hover only.
class OurnegoIconMotionBox extends StatelessWidget {
  const OurnegoIconMotionBox({
    super.key,
    required this.motion,
    required this.active,
    required this.child,
  });

  static const Duration _duration = Duration(milliseconds: 220);

  final OurnegoIconMotion motion;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (motion == OurnegoIconMotion.none) return child;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: active ? 1 : 0),
      duration: _duration,
      curve: reduced ? Curves.easeOut : kOurnegoSpring,
      child: child,
      builder: (context, value, child) {
        if (motion == OurnegoIconMotion.nudge) {
          return Transform.translate(
            offset: Offset(3 * value, 0),
            child: child,
          );
        }
        return Transform.rotate(
          angle: -10 * math.pi / 180 * value,
          child: Transform.scale(scale: 1 + 0.12 * value, child: child),
        );
      },
    );
  }
}

/// Runs the toggle "pop" on its child whenever [value] changes (spec §3.6):
/// 0→40% scale 1→1.45 and rotate 0→-10°, then back, with kOurnegoSpring.
/// Disabled with reduced motion.
class OurnegoIconPop extends StatefulWidget {
  const OurnegoIconPop({super.key, required this.value, required this.child});

  final Object? value;
  final Widget child;

  @override
  State<OurnegoIconPop> createState() => _OurnegoIconPopState();
}

class _OurnegoIconPopState extends State<OurnegoIconPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kIconPopDuration);
  }

  @override
  void didUpdateWidget(covariant OurnegoIconPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.value != oldWidget.value && !reduced) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (!_controller.isAnimating) return child!;
        final t = _controller.value;
        final double u = t <= 0.4
            ? kOurnegoSpring.transform(t / 0.4)
            : 1 - kOurnegoSpring.transform((t - 0.4) / 0.6);
        return Transform.rotate(
          angle: -10 * math.pi / 180 * u,
          child: Transform.scale(scale: 1 + 0.45 * u, child: child),
        );
      },
    );
  }
}

/// Resolves [OurnegoButtonColors] for a tone in the current theme.
OurnegoButtonColors ournegoToneColors(
  BuildContext context,
  OurnegoButtonTone tone, {
  bool? outlined,
}) {
  return OurnegoButtonPalette.of(
    tone,
    Theme.of(context).colorScheme,
    outlined: outlined,
  );
}

/// Whether reduced motion is requested.
bool ournegoReducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
