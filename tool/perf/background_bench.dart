// Frame-timing benchmark for the animated background (OUR-157).
//
// Mounts the real `OurnegoPageLayout` / `AnimatedBackground` with the same
// glass pieces the app paints on top of it (blurred content container, dialog
// surface) and runs a scripted route: idle drift, page pushes/pops, dialogs
// and an onboarding-style page swipe. Frame timings come from the engine
// (`FrameTiming`), so the numbers are the same ones DevTools shows. It needs
// no backend, so a run is repeatable.
//
// Run it on a real device in profile mode:
//
//   flutter run --profile -d <device> -t tool/perf/background_bench.dart \
//     --dart-define=BENCH_LABEL=baseline
//
// and read the `BENCH_RESULT {...}` line from the console. See
// docs/development/performance/animated-background.md.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:math' as math;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/routing/route_observer.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';

const String _label = String.fromEnvironment(
  'BENCH_LABEL',
  defaultValue: 'run',
);
// Control run: same pages and glass without the animated background.
const bool _noBackground = bool.fromEnvironment('BENCH_NO_BG');
const int _cycles = int.fromEnvironment('BENCH_CYCLES', defaultValue: 8);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BenchApp());
}

class _Phase {
  _Phase(this.name, this.startUs, this.endUs);
  final String name;
  final int startUs;
  final int endUs;
}

class _BenchApp extends StatefulWidget {
  const _BenchApp();

  @override
  State<_BenchApp> createState() => _BenchAppState();
}

class _BenchAppState extends State<_BenchApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final List<FrameTiming> _timings = [];
  final List<_Phase> _phases = [];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    // Let the first frames and the shader compilation settle.
    Future<void>.delayed(const Duration(seconds: 4), _run);
  }

  Future<void> _wait(Duration d) => Future<void>.delayed(d);

  Future<void> _measure(String name, Future<void> Function() body) async {
    final start = Timeline.now;
    await body();
    _phases.add(_Phase(name, start, Timeline.now));
  }

  Future<void> _run() async {
    final nav = _navigatorKey.currentState!;

    await _measure('idle', () => _wait(const Duration(seconds: 12)));

    await _measure('push_pop', () async {
      for (var i = 0; i < _cycles; i++) {
        nav.push(MaterialPageRoute<void>(builder: (_) => const _GlassPage()));
        await _wait(const Duration(milliseconds: 1400));
        nav.pop();
        await _wait(const Duration(milliseconds: 1000));
      }
    });

    await _measure('dialog', () async {
      for (var i = 0; i < _cycles; i++) {
        unawaited(
          showOurnegoDialog<void>(
            // ignore: use_build_context_synchronously
            context: nav.context,
            builder: (_) => const Center(
              child: SizedBox(
                width: 300,
                child: OurnegoDialogSurface(
                  child: Text('Dialog over the animated background'),
                ),
              ),
            ),
          ),
        );
        await _wait(const Duration(milliseconds: 1200));
        nav.pop();
        await _wait(const Duration(milliseconds: 900));
      }
    });

    await _measure('page_swipe', () async {
      nav.push(MaterialPageRoute<void>(builder: (_) => const _SwipePage()));
      await _wait(const Duration(milliseconds: 1500));
      for (var i = 0; i < _cycles; i++) {
        _SwipePage.controller.animateToPage(
          (i + 1) % 2,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        await _wait(const Duration(milliseconds: 1100));
      }
      nav.pop();
      await _wait(const Duration(milliseconds: 600));
    });

    // FrameTiming callbacks are batched; give the last ones time to arrive.
    await _wait(const Duration(seconds: 2));
    _report();
  }

  void _report() {
    final result = <String, Object>{
      'label': _label,
      'mode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
      'phases': {
        for (final phase in _phases)
          phase.name: _summarize(
            _timings.where((t) {
              final at = t.timestampInMicroseconds(FramePhase.buildStart);
              return at >= phase.startUs && at < phase.endUs;
            }).toList(),
            phase.endUs - phase.startUs,
          ),
      },
    };
    debugPrint('BENCH_RESULT ${jsonEncode(result)}');
  }

  Map<String, Object> _summarize(List<FrameTiming> frames, int spanUs) {
    double ms(Duration d) => d.inMicroseconds / 1000;
    double pct(List<double> sorted, double p) => sorted.isEmpty
        ? 0
        : sorted[math.min(sorted.length - 1, (sorted.length * p).floor())];
    double round(double v) => (v * 100).round() / 100;

    final build = frames.map((f) => ms(f.buildDuration)).toList()..sort();
    final raster = frames.map((f) => ms(f.rasterDuration)).toList()..sort();
    final total = frames.map((f) => ms(f.totalSpan)).toList()..sort();
    double mean(List<double> v) =>
        v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

    return {
      'frames': frames.length,
      'fps': round(frames.length / (spanUs / 1e6)),
      'buildMeanMs': round(mean(build)),
      'buildP90Ms': round(pct(build, 0.9)),
      'buildP99Ms': round(pct(build, 0.99)),
      'rasterMeanMs': round(mean(raster)),
      'rasterP90Ms': round(pct(raster, 0.9)),
      'rasterP99Ms': round(pct(raster, 0.99)),
      'rasterWorstMs': round(raster.isEmpty ? 0 : raster.last),
      'totalP99Ms': round(pct(total, 0.99)),
      // Frames that did not fit the 60 Hz and the 120 Hz budgets.
      'over16_7ms': total.where((v) => v > 16.67).length,
      'over8_3ms': total.where((v) => v > 8.33).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
      navigatorObservers: [AppRouteObserver.instance],
      home: const _GlassPage(),
    );
  }
}

class _GlassPage extends StatelessWidget {
  const _GlassPage();

  @override
  Widget build(BuildContext context) {
    const content = Center(
      child: OurnegoContentContainer(
        hasBlur: true,
        child: Text('Glass content over the animated background'),
      ),
    );
    return _noBackground
        ? const Scaffold(body: content)
        : const OurnegoPageLayout(child: content);
  }
}

class _SwipePage extends StatelessWidget {
  const _SwipePage();

  static final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    final pages = PageView(
      controller: controller,
      children: const [
        Center(child: OurnegoContentContainer(child: Text('Page 1'))),
        Center(child: OurnegoContentContainer(child: Text('Page 2'))),
      ],
    );
    return _noBackground
        ? Scaffold(body: pages)
        : OurnegoPageLayout(child: pages);
  }
}
