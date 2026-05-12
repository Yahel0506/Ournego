import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nego_mood.dart';
import 'nego_motion_controller.dart';
import 'nego_painter.dart';

class NegoAvatar extends StatefulWidget {
  const NegoAvatar({
    super.key,
    this.size = 256,
    this.mood = NegoMood.idle,
    this.lookAngle = -18,
    this.lookVertical = NegoLookVertical.down,
    this.interactive = true,
    this.onTap,
  });

  final double size;
  final NegoMood mood;
  final double lookAngle;
  final NegoLookVertical lookVertical;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  State<NegoAvatar> createState() => _NegoAvatarState();
}

class _NegoAvatarState extends State<NegoAvatar>
    with TickerProviderStateMixin {
  late final NegoMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NegoMotionController(
      vsync: this,
      mood: widget.mood,
      lookAngle: widget.lookAngle,
      lookVertical: widget.lookVertical,
      interactive: widget.interactive,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setTickerModeEnabled(TickerMode.valuesOf(context).enabled);
  }

  @override
  void didUpdateWidget(covariant NegoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.updateConfiguration(
      mood: widget.mood,
      lookAngle: widget.lookAngle,
      lookVertical: widget.lookVertical,
      interactive: widget.interactive,
    );
    _controller.setTickerModeEnabled(TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.interactive) return;

    _controller.triggerHappy();
    widget.onTap?.call();
  }

  void _handlePointer(Offset localPosition) {
    if (!widget.interactive) return;

    final double normalizedX = ((localPosition.dx / widget.size) * 2) - 1;
    final double normalizedY = ((localPosition.dy / widget.size) * 2) - 1;
    _controller.updatePointer(Offset(
      normalizedX.clamp(-1.0, 1.0),
      normalizedY.clamp(-1.0, 1.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget avatar = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: NegoPainter(
            size: widget.size,
            geometry: _controller.geometry,
            motion: _controller.motionValues,
            mood: _controller.activeMood,
          ),
        );
      },
    );

    final Widget interactiveChild = MouseRegion(
      onExit: (_) => _controller.updatePointer(Offset.zero),
      child: Listener(
        onPointerDown: (event) => _handlePointer(event.localPosition),
        onPointerMove: (event) => _handlePointer(event.localPosition),
        onPointerHover: (event) => _handlePointer(event.localPosition),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.interactive ? _handleTap : null,
          child: avatar,
        ),
      ),
    );

    final Widget focusable = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              _handleTap();
              return null;
            },
          ),
        },
        child: FocusableActionDetector(
          enabled: widget.interactive,
          mouseCursor:
              widget.interactive ? SystemMouseCursors.click : MouseCursor.defer,
          child: interactiveChild,
        ),
      ),
    );

    return RepaintBoundary(
      child: Semantics(
        button: widget.interactive,
        enabled: widget.interactive,
        label: widget.interactive ? 'Interactuar con Nego' : null,
        onTap: widget.interactive ? _handleTap : null,
        child: SizedBox.square(
          dimension: widget.size,
          child: widget.interactive ? focusable : avatar,
        ),
      ),
    );
  }
}
