import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/startup/startup_controller.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

typedef StartupAppBuilder = Widget Function(bool startOnMap);
typedef StartupSupportLauncher = Future<bool> Function(Uri uri);

/// Builds the animated splash. It must call `onAnimationCompleted` once the
/// animation reaches its final (static) logo frame.
typedef StartupSplashBuilder =
    Widget Function(VoidCallback onAnimationCompleted);

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.controller,
    required this.appBuilder,
    this.supportLauncher = _launchSupport,
    this.splashBuilder,
    this.splashMinimumHold = const Duration(milliseconds: 500),
    this.splashExitDuration = const Duration(milliseconds: 900),
  });

  final StartupController controller;
  final StartupAppBuilder appBuilder;
  final StartupSupportLauncher supportLauncher;

  /// Animated splash shown over startup; null disables it (web).
  ///
  /// The splash always plays to its final logo. The logo then stays static
  /// for at least [splashMinimumHold] and until startup settles (app ready or
  /// startup error), while the app is built underneath it. Finally the splash
  /// blurs and slides away over [splashExitDuration], revealing the app.
  final StartupSplashBuilder? splashBuilder;
  final Duration splashMinimumHold;
  final Duration splashExitDuration;

  static Future<bool> _launchSupport(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<StartupGate> createState() => _StartupGateState();
}

enum _SplashPhase { playing, holding, exiting, done }

class _StartupGateState extends State<StartupGate>
    with SingleTickerProviderStateMixin {
  late _SplashPhase _splashPhase = widget.splashBuilder == null
      ? _SplashPhase.done
      : _SplashPhase.playing;
  bool _splashHoldElapsed = false;
  Timer? _splashHoldTimer;
  late final AnimationController _splashExit;
  // Built once so splash phase changes never rebuild the app subtree.
  Widget? _app;

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    // Reveal only after the frame that builds the app (or the error screen)
    // underneath the splash, so its first heavy build never stalls the exit.
    if (_splashPhase == _SplashPhase.holding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeExitSplash());
    }
  }

  void _onSplashAnimationCompleted() {
    if (!mounted || _splashPhase != _SplashPhase.playing) return;
    // Builds the app (if ready) under the logo while the hold runs.
    setState(() => _splashPhase = _SplashPhase.holding);
    _splashHoldTimer = Timer(widget.splashMinimumHold, () {
      _splashHoldElapsed = true;
      _maybeExitSplash();
    });
  }

  void _maybeExitSplash() {
    if (!mounted ||
        _splashPhase != _SplashPhase.holding ||
        !_splashHoldElapsed ||
        widget.controller.state.isStarting) {
      return;
    }
    setState(() => _splashPhase = _SplashPhase.exiting);
    _splashExit.forward();
  }

  @override
  void initState() {
    super.initState();
    _splashExit =
        AnimationController(vsync: this, duration: widget.splashExitDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _splashPhase = _SplashPhase.done);
            }
          });
    widget.controller.addListener(_onControllerChanged);
    widget.controller.start();
  }

  @override
  void didUpdateWidget(covariant StartupGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.dispose();
      _app = null;
      widget.controller.addListener(_onControllerChanged);
      widget.controller.start();
    }
  }

  @override
  void dispose() {
    _splashHoldTimer?.cancel();
    _splashExit.dispose();
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    final state = widget.controller.state;
    // The app is first built under the static logo, so its heavy first build
    // never stalls the splash animation.
    if (state.isReady && _splashPhase != _SplashPhase.playing) {
      return _app ??= widget.appBuilder(state.startOnMap);
    }
    // The splash already tells the user Ournego is starting.
    if (state.failure == null && _splashPhase != _SplashPhase.done) {
      return const SizedBox.shrink();
    }
    return MaterialApp(
      title: 'Ournego',
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
      home: _StartupStatusScreen(
        state: state,
        onRetry: widget.controller.retry,
        supportLauncher: widget.supportLauncher,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final splashBuilder = widget.splashBuilder;
    if (splashBuilder == null) return content;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Keyed so the app keeps its state when the splash layer is removed.
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: const ValueKey('startup-content'),
          child: _SplashReveal(
            animation: _splashExit,
            active: _splashPhase == _SplashPhase.exiting,
            reduceMotion: reduceMotion,
            child: content,
          ),
        ),
        if (_splashPhase != _SplashPhase.done)
          KeyedSubtree(
            key: const ValueKey('startup-splash'),
            child: _SplashExit(
              animation: _splashExit,
              exiting: _splashPhase == _SplashPhase.exiting,
              reduceMotion: reduceMotion,
              child: _SplashBackdrop(
                child: splashBuilder(_onSplashAnimationCompleted),
              ),
            ),
          ),
      ],
    );
  }
}

/// Theme-aware background with the splash centered on it.
class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? OurnegoColors.darkTheme : OurnegoColors.lightTheme;
    final size = (MediaQuery.sizeOf(context).shortestSide * 0.72).clamp(
      0.0,
      320.0,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: SizedBox.square(dimension: size, child: child),
        ),
      ),
    );
  }
}

/// Splash layer: drifts up while it blurs and fades out.
class _SplashExit extends StatelessWidget {
  const _SplashExit({
    required this.animation,
    required this.exiting,
    required this.reduceMotion,
    required this.child,
  });

  static const _slide = Curves.fastOutSlowIn;
  static const _blur = Interval(0.0, 0.7, curve: Curves.easeOut);
  static const _fade = Interval(0.1, 0.85, curve: Curves.easeInOut);

  final Animation<double> animation;
  final bool exiting;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: exiting,
      // Blocks touches to the app underneath while the splash covers it.
      child: AbsorbPointer(
        absorbing: !exiting,
        child: AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value;
            final opacity = 1 - _fade.transform(t);
            if (reduceMotion) return Opacity(opacity: opacity, child: child);
            final sigma = 20 * _blur.transform(t);
            return Opacity(
              opacity: opacity,
              child: ImageFiltered(
                enabled: sigma > 0.01,
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.decal,
                ),
                child: FractionalTranslation(
                  translation: Offset(0, -0.22 * _slide.transform(t)),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Content layer: settles in from slightly below while it comes into focus.
///
/// It always builds the same widget tree (filter disabled, zero offset when
/// idle) so the app never loses state when the splash starts or ends.
class _SplashReveal extends StatelessWidget {
  const _SplashReveal({
    required this.animation,
    required this.active,
    required this.reduceMotion,
    required this.child,
  });

  static const _settle = Interval(0.15, 1.0, curve: Curves.easeOutCubic);

  final Animation<double> animation;
  final bool active;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final remaining = reduceMotion || !active
            ? 0.0
            : 1 - _settle.transform(animation.value);
        final sigma = 12 * remaining;
        return ImageFiltered(
          enabled: sigma > 0.01,
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: FractionalTranslation(
            translation: Offset(0, 0.04 * remaining),
            child: child,
          ),
        );
      },
    );
  }
}

class _StartupStatusScreen extends StatefulWidget {
  const _StartupStatusScreen({
    required this.state,
    required this.onRetry,
    required this.supportLauncher,
  });

  final StartupState state;
  final VoidCallback onRetry;
  final StartupSupportLauncher supportLauncher;

  @override
  State<_StartupStatusScreen> createState() => _StartupStatusScreenState();
}

class _StartupStatusScreenState extends State<_StartupStatusScreen> {
  bool _couldNotOpenSupport = false;

  Future<void> _showHelp() async {
    final failure = widget.state.failure;
    final body = switch (failure?.kind) {
      StartupErrorKind.configuration =>
        'Esta instalación necesita una corrección. Actualiza Ournego o contacta al equipo de soporte.',
      StartupErrorKind.preparation =>
        'Ournego no pudo preparar un servicio local. Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, contacta al equipo de soporte.',
      StartupErrorKind.initialization =>
        'Ournego no terminó de iniciar. Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, contacta al equipo de soporte.',
      StartupErrorKind.timeout =>
        'El inicio tardó demasiado. Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, contacta al equipo de soporte.',
      null => 'Espera un momento mientras preparamos Ournego.',
    };

    await showOurnegoDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ayuda para iniciar Ournego'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(body),
                if (_couldNotOpenSupport) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'No pudimos abrir el canal de consultas. Puedes volver a intentarlo más tarde.',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            OurnegoButton.text(
              size: OurnegoButtonSize.compact,
              label: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
            ),
            OurnegoButton.primary(
              size: OurnegoButtonSize.compact,
              label: 'Contactar soporte',
              onPressed: () async {
                var opened = false;
                try {
                  opened = await widget.supportLauncher(
                    Uri.parse('https://wa.me/3411768237'),
                  );
                } catch (_) {
                  opened = false;
                }
                if (!opened && context.mounted) {
                  setDialogState(() => _couldNotOpenSupport = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = widget.state.failure;
    final isStarting = widget.state.isStarting;
    final title = isStarting
        ? 'Preparando Ournego'
        : failure?.kind == StartupErrorKind.configuration
        ? 'Ournego no puede iniciar'
        : 'No pudimos iniciar Ournego';
    final explanation = isStarting
        ? 'Estamos preparando la aplicación.'
        : failure?.kind == StartupErrorKind.configuration
        ? 'Esta instalación necesita una corrección para funcionar.'
        : failure?.canRetry == true
        ? 'Puedes intentar iniciar una vez más.'
        : 'Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, consulta la ayuda.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isStarting ? Icons.hourglass_top : Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    explanation,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (isStarting) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                  if (failure != null) ...[
                    const SizedBox(height: 24),
                    if (failure.canRetry)
                      OurnegoButton.primary(
                        label: 'Reintentar',
                        icon: Icons.refresh_rounded,
                        iconMotion: OurnegoIconMotion.wiggle,
                        onPressed: widget.onRetry,
                      ),
                    const SizedBox(height: 12),
                    OurnegoButton.secondary(
                      label: 'Ver ayuda',
                      icon: Icons.help_outline_rounded,
                      onPressed: _showHelp,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
