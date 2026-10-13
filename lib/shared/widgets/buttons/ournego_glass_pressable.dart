import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// Core of the flat glass line (spec §5.7): glass face with blur, 1 px
/// contour, calm press scale and no lip, boing, pop or burst. Curves never
/// overshoot: never use `kOurnegoSpring` here.
class OurnegoGlassPressable extends StatefulWidget {
  const OurnegoGlassPressable({
    super.key,
    required this.onPressed,
    required this.child,
    required this.height,
    this.width,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.active = false,
    this.showHalo = false,
    this.semanticLabel,
    this.tooltip,
    this.toggled,
    this.focusNode,
    this.forcePressed = false,
  });

  /// Null means disabled.
  final VoidCallback? onPressed;
  final Widget child;

  /// 52 (icon) or 40 (chip).
  final double height;

  /// Null means intrinsic.
  final double? width;

  /// Null means a circle.
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  /// Accent contour and ink, e.g. the microphone while listening.
  final bool active;

  /// Animated listening halo while [active].
  final bool showHalo;
  final String? semanticLabel;
  final String? tooltip;
  final bool? toggled;
  final FocusNode? focusNode;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  /// Pressed scale (spec §3.6).
  static const double pressedScale = 0.96;

  /// Icon scale on hover.
  static const double hoverIconScale = 1.06;

  @override
  State<OurnegoGlassPressable> createState() => _OurnegoGlassPressableState();
}

/// Key of the scaled glass element, used by tests.
const ValueKey<String> ournegoGlassScaleKey = ValueKey<String>(
  'ournegoGlassScale',
);

/// Key of the listening halo, used by tests.
const ValueKey<String> ournegoListeningHaloKey = ValueKey<String>(
  'ournegoListeningHalo',
);

class _OurnegoGlassPressableState extends State<OurnegoGlassPressable>
    with SingleTickerProviderStateMixin {
  // 0 = rest, 1 = pressed. Bounded, so scale can never pass 1.0.
  late final AnimationController _press;

  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      value: widget.forcePressed ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant OurnegoGlassPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forcePressed != oldWidget.forcePressed) {
      _press.value = widget.forcePressed ? 1 : 0;
    }
    if (!_enabled) {
      _hovered = false;
      if (!widget.forcePressed) _press.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() {
    if (!_enabled || widget.forcePressed) return;
    _press.animateTo(1, duration: kGlassPressDuration, curve: Curves.easeOut);
  }

  void _up() {
    if (widget.forcePressed) return;
    _press.animateTo(0, duration: kGlassReleaseDuration, curve: kCalmCurve);
  }

  Future<void> _activateFromKeyboard() async {
    if (!_enabled) return;
    _down();
    await Future<void>.delayed(kGlassPressDuration);
    if (!mounted) return;
    _up();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 4096;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    final Color border;
    if (!_enabled) {
      border = OurnegoSemanticTokens.borderMuted(scheme);
    } else if (widget.active) {
      border = OurnegoGlassPalette.active(scheme);
    } else if (_hovered) {
      border = OurnegoGlassPalette.borderHover(scheme);
    } else {
      border = OurnegoGlassPalette.border(scheme);
    }
    final ink = widget.active
        ? OurnegoGlassPalette.active(scheme)
        : scheme.onSurface;
    final animate = _enabled;

    Widget content = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: ink),
      duration: animate ? kGlassHoverDuration : Duration.zero,
      curve: Curves.easeOut,
      child: widget.child,
      builder: (context, color, child) => IconTheme.merge(
        data: IconThemeData(
          color: color,
          size: OurnegoComponentMetrics.glassIconSize,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onSurface),
          child: child!,
        ),
      ),
    );
    content = AnimatedScale(
      scale: _hovered && _enabled ? OurnegoGlassPressable.hoverIconScale : 1,
      duration: animate ? kGlassReleaseDuration : Duration.zero,
      curve: kCalmCurve,
      child: content,
    );
    if (!_enabled) content = Opacity(opacity: 0.38, child: content);

    final glass = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: OurnegoGlassPalette.blurSigma,
          sigmaY: OurnegoGlassPalette.blurSigma,
        ),
        child: AnimatedContainer(
          duration: animate ? kGlassHoverDuration : Duration.zero,
          curve: Curves.easeOut,
          height: widget.height,
          width: widget.width,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: OurnegoGlassPalette.face(scheme),
            borderRadius: radius,
            border: Border.all(
              color: border,
              width: OurnegoComponentMetrics.borderWidth,
            ),
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        ),
      ),
    );

    final ringOffset =
        OurnegoComponentMetrics.focusRingWidth +
        OurnegoComponentMetrics.focusRingGap;

    Widget body = AnimatedBuilder(
      animation: _press,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.active && widget.showHalo)
            Positioned.fill(
              child: _ListeningHalo(
                key: ournegoListeningHaloKey,
                borderRadius: radius,
              ),
            ),
          glass,
          if (_focused && _enabled)
            Positioned(
              left: -ringOffset,
              top: -ringOffset,
              right: -ringOffset,
              bottom: -ringOffset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius + BorderRadius.circular(ringOffset),
                    border: Border.all(
                      color: OurnegoButtonPalette.focusRing(scheme),
                      width: OurnegoComponentMetrics.focusRingWidth,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      builder: (context, child) {
        final scale = lerpDouble(
          1,
          OurnegoGlassPressable.pressedScale,
          _press.value,
        )!;
        return Transform.scale(
          key: ournegoGlassScaleKey,
          scale: scale,
          child: child,
        );
      },
    );

    body = FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
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
      onShowHoverHighlight: (value) {
        if (_hovered != value) setState(() => _hovered = value);
      },
      onShowFocusHighlight: (value) {
        if (_focused != value) setState(() => _focused = value);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: _enabled ? (_) => _down() : null,
        onTapUp: _enabled ? (_) => _up() : null,
        onTapCancel: _enabled ? _up : null,
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.max(0, screenWidth)),
          child: body,
        ),
      ),
    );

    if (widget.tooltip != null) {
      body = Tooltip(message: widget.tooltip!, child: body);
    }

    return OurnegoMinTapTarget(
      child: Semantics(
        container: true,
        button: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        toggled: widget.toggled,
        focusable: _enabled ? true : null,
        focused: _enabled ? _focused : null,
        excludeSemantics: widget.semanticLabel != null,
        onTap: widget.onPressed,
        child: body,
      ),
    );
  }
}

/// One 1 px ring around the microphone that grows 1 → 1.32 while fading
/// 0.6 → 0, looping with easeOut. With reduced motion it stays still at 40%
/// opacity (the scale where the loop reaches 40%).
class _ListeningHalo extends StatefulWidget {
  const _ListeningHalo({super.key, required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  State<_ListeningHalo> createState() => _ListeningHaloState();
}

class _ListeningHaloState extends State<_ListeningHalo>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 1.32;
  static const double _startOpacity = 0.6;
  static const double _reducedOpacity = 0.4;

  late final AnimationController _controller;
  bool? _reduced;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kListeningHaloPeriod,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced == _reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller.stop();
      // Opacity 0.6 -> 0 is linear in the eased value, so 40% happens at 1/3.
      _controller.value = 1 - _reducedOpacity / _startOpacity;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final reduced = _reduced ?? false;
          final u = reduced
              ? _controller.value
              : Curves.easeOut.transform(_controller.value);
          return Transform.scale(
            scale: lerpDouble(1, _maxScale, u)!,
            child: Opacity(
              opacity: lerpDouble(_startOpacity, 0, u)!,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  border: Border.all(
                    color: OurnegoGlassPalette.halo,
                    width: OurnegoComponentMetrics.borderWidth,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
