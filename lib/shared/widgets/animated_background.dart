import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/routing/route_observer.dart';

class AnimatedBackgroundBlob {
  const AnimatedBackgroundBlob({
    required this.color,
    required this.width,
    required this.height,
    this.opacity = 0.4,
  });

  final Color color;
  final double width;
  final double height;
  final double opacity;
}

/// Soft drifting color blobs behind a screen.
///
/// Each blob is a small image, rendered once, of a disc blurred with a
/// Gaussian of [blurSigma]; every frame only draws those images at their new
/// position. There is no `BackdropFilter`, which forced a full-screen offscreen
/// blur of everything below it on every frame (and on every frame of a route
/// or dialog transition), and no per-frame gradient shader. The drift is
/// driven by one controller that repaints a single [CustomPainter] inside its
/// own [RepaintBoundary]; nothing is rebuilt or re-laid-out per frame. See
/// docs/development/performance/animated-background.md.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    this.blobs,
    this.animationDuration = kBackgroundDriftDuration,
    this.blurSigma = 80,
  });

  final List<AnimatedBackgroundBlob>? blobs;
  final Duration animationDuration;

  /// Softness of the blob edges: the sigma of the Gaussian blur the gradient
  /// imitates.
  final double blurSigma;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with
        WidgetsBindingObserver,
        RouteAware,
        SingleTickerProviderStateMixin<AnimatedBackground> {
  static const List<AnimatedBackgroundBlob> _defaultBlobs = [
    AnimatedBackgroundBlob(
      color: OurnegoColors.aguamarina,
      width: 300,
      height: 300,
      opacity: 0.4,
    ),
    AnimatedBackgroundBlob(
      color: OurnegoColors.azulCielo,
      width: 350,
      height: 350,
      opacity: 0.3,
    ),
    AnimatedBackgroundBlob(
      color: OurnegoColors.verdeCastleton,
      width: 250,
      height: 250,
      opacity: 0.1,
    ),
  ];

  final Random _random = Random();
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  Timer? _timer;

  // Blob centers as fractions of the canvas, so a resize needs no reset.
  final _DriftPath _path = _DriftPath();
  List<_BlobSprite> _sprites = const [];
  bool _reducedMotion = false;
  bool _covered = false;
  bool _inForeground = true;

  List<AnimatedBackgroundBlob> get _blobs => widget.blobs ?? _defaultBlobs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _path.reset(_randomCenters());
    _buildSprites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      AppRouteObserver.instance.subscribe(this, modalRoute);
    }
    _syncTimer();
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
      _stopTimer();
      _syncTimer();
    }
    if (_blobs.length != _path.to.length) {
      _path.reset(_randomCenters());
    }
    if (!identical(oldWidget.blobs, widget.blobs) ||
        oldWidget.blurSigma != widget.blurSigma) {
      _buildSprites();
    }
  }

  void _buildSprites() {
    for (final sprite in _sprites) {
      sprite.dispose();
    }
    _sprites = [
      for (final blob in _blobs) _BlobSprite.render(blob, widget.blurSigma),
    ];
  }

  List<Offset> _randomCenters() => List<Offset>.generate(
    _blobs.length,
    (_) => Offset(_random.nextDouble(), _random.nextDouble()),
    growable: false,
  );

  bool get _shouldAnimate => !_reducedMotion && !_covered && _inForeground;

  /// Starts or stops the drift so it only runs while the background is
  /// visible, in the foreground and motion is allowed.
  void _syncTimer() {
    if (!_shouldAnimate) {
      _stopTimer();
      return;
    }
    if (_timer?.isActive ?? false) return;
    _drift();
    _timer = Timer.periodic(widget.animationDuration, (_) => _drift());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _controller.stop();
  }

  /// Heads for new random centers, starting from where the blobs are now.
  void _drift() {
    if (!mounted) return;
    _path.retarget(_randomCenters(), _curve.value);
    _controller.forward(from: 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  @override
  void didPushNext() {
    _covered = true;
    _syncTimer();
  }

  @override
  void didPopNext() {
    _covered = false;
    _syncTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRouteObserver.instance.unsubscribe(this);
    _timer?.cancel();
    for (final sprite in _sprites) {
      sprite.dispose();
    }
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: ClipRect(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _BlobsPainter(
                sprites: _sprites,
                path: _path,
                progress: _curve,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where each blob center is going: from [from] to [to] as progress goes 0..1.
class _DriftPath {
  List<Offset> from = const [];
  List<Offset> to = const [];

  void reset(List<Offset> centers) {
    from = centers;
    to = centers;
  }

  /// Heads for [next], starting from where the blobs are at [progress].
  void retarget(List<Offset> next, double progress) {
    from = [
      for (var i = 0; i < to.length; i++)
        Offset.lerp(from[i], to[i], progress)!,
    ];
    to = next;
  }
}

class _BlobsPainter extends CustomPainter {
  _BlobsPainter({
    required this.sprites,
    required this.path,
    required this.progress,
  }) : super(repaint: progress);

  final List<_BlobSprite> sprites;
  final _DriftPath path;
  final Animation<double> progress;

  // Bilinear sampling hides the low resolution of the sprites; the gradient is
  // smooth, so no detail is lost.
  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.low
    ..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final to = path.to;
    for (var i = 0; i < sprites.length && i < to.length; i++) {
      final sprite = sprites[i];
      final center = Offset.lerp(path.from[i], to[i], t)!;
      canvas.drawImageRect(
        sprite.image,
        sprite.source,
        Rect.fromCenter(
          center: Offset(center.dx * size.width, center.dy * size.height),
          width: sprite.width,
          height: sprite.height,
        ),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BlobsPainter old) =>
      old.sprites != sprites || old.path != path || old.progress != progress;
}

/// A blob rendered once: a disc of the blob's size blurred with a Gaussian,
/// tinted with its color and opacity, in a small image that is scaled up when
/// drawn.
class _BlobSprite {
  _BlobSprite._(this.image, this.width, this.height);

  /// Side of the rendered image in pixels. The blob is smooth, so a small
  /// image scaled up with bilinear filtering is indistinguishable from a
  /// full-resolution one.
  static const int _resolution = 160;
  static const int _rings = 40;
  static const int _angles = 36;

  final ui.Image image;

  /// Size on screen, in logical pixels.
  final double width;
  final double height;

  Rect get source =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  void dispose() => image.dispose();

  static _BlobSprite render(AnimatedBackgroundBlob blob, double sigma) {
    final minSide = min(blob.width, blob.height);
    final radius = minSide / 2;
    // Distance from the center where the blob has faded out.
    final extent = sigma <= 0 ? radius : radius + 2.6 * sigma;
    final stretchX = blob.width / minSide;
    final stretchY = blob.height / minSide;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final pixelsPerUnit = _resolution / (2 * extent);
    canvas.scale(pixelsPerUnit);
    canvas.translate(extent, extent);
    canvas.drawCircle(
      Offset.zero,
      extent,
      Paint()
        ..shader = RadialGradient(
          colors: [
            for (final v in _profile(radius, sigma, extent))
              blob.color.withValues(alpha: blob.opacity * v),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: extent)),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_resolution, _resolution);
    picture.dispose();
    return _BlobSprite._(image, 2 * extent * stretchX, 2 * extent * stretchY);
  }

  /// Intensity (0..1) of a disc of [radius] blurred with a Gaussian of
  /// [sigma], at evenly spaced distances from the center up to [extent]. The
  /// last value is forced to 0 so the sprite ends fully transparent.
  static List<double> _profile(double radius, double sigma, double extent) {
    const samples = 24;
    if (sigma <= 0) return List<double>.filled(samples, 1);
    final norm = 1 / (2 * pi * sigma * sigma);
    final area = (radius / _rings) * (2 * pi / _angles);
    final values = <double>[];
    for (var s = 0; s < samples; s++) {
      final d = extent * s / (samples - 1);
      var sum = 0.0;
      for (var a = 0; a < _rings; a++) {
        final rho = radius * (a + 0.5) / _rings;
        for (var b = 0; b < _angles; b++) {
          final theta = 2 * pi * (b + 0.5) / _angles;
          final dx = d - rho * cos(theta);
          final dy = rho * sin(theta);
          sum += exp(-(dx * dx + dy * dy) / (2 * sigma * sigma)) * rho;
        }
      }
      values.add((sum * area * norm).clamp(0.0, 1.0));
    }
    values[samples - 1] = 0;
    return values;
  }
}
