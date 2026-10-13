import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

const kOurnegoSplashAsset = 'assets/splash/ournego_splash.webp';

/// Plays the Ournego splash (animated WebP, transparent background) once.
///
/// [onAnimationCompleted] fires as soon as the final logo frame is on screen:
/// the long duration baked into that last frame is ignored, so the caller
/// decides how long the logo stays static. The last frame stays visible.
/// If the asset cannot be decoded the callback fires right away so startup is
/// never blocked by the splash.
class OurnegoSplashAnimation extends StatefulWidget {
  const OurnegoSplashAnimation({
    super.key,
    required this.onAnimationCompleted,
    this.asset = kOurnegoSplashAsset,
  });

  final VoidCallback onAnimationCompleted;
  final String asset;

  @override
  State<OurnegoSplashAnimation> createState() => _OurnegoSplashAnimationState();
}

class _OurnegoSplashAnimationState extends State<OurnegoSplashAnimation> {
  ui.Image? _frame;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_play());
  }

  Future<void> _play() async {
    ui.Codec? codec;
    try {
      final data = await rootBundle.load(widget.asset);
      codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      // Start once Flutter is on screen, not while the native launch screen
      // still covers it.
      await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
      final clock = Stopwatch()..start();
      var target = Duration.zero;
      var pending = codec.getNextFrame();

      for (var i = 0; i < codec.frameCount; i++) {
        final info = await pending;
        if (_disposed) {
          info.image.dispose();
          return;
        }
        _show(info.image);
        if (i == codec.frameCount - 1) break;

        // Decode the next frame while this one is on screen.
        pending = codec.getNextFrame();
        target += info.duration;
        var wait = target - clock.elapsed;
        if (wait < Duration.zero) {
          // After a stall resume at normal speed instead of rushing frames to
          // catch up: the animation must always be seen in full.
          target = clock.elapsed;
          wait = Duration.zero;
        }
        await Future<void>.delayed(wait);
        if (_disposed) {
          (await pending).image.dispose();
          return;
        }
      }
    } catch (error) {
      debugPrint('No se pudo reproducir el splash: $error');
    } finally {
      codec?.dispose();
    }
    if (!_disposed) widget.onAnimationCompleted();
  }

  void _show(ui.Image image) {
    final old = _frame;
    setState(() => _frame = image);
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawImage(
      image: _frame,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
