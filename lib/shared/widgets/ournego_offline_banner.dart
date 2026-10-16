import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/network/connectivity_providers.dart';
import 'package:ournego/core/network/reconnect_refresh.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

enum _Phase { hidden, offline, restored }

/// Wraps the app and shows a banner over it while the device is offline.
///
/// It slides in over the content (it does not push it down), turns green in
/// place when the connection is back, stays a moment and slides out. On
/// reconnection it reloads remote data that may have failed.
class OurnegoOfflineBanner extends ConsumerStatefulWidget {
  const OurnegoOfflineBanner({super.key, required this.child});

  final Widget child;

  /// How long "connection restored" stays on screen.
  static const Duration restoredFor = Duration(milliseconds: 2500);

  @override
  ConsumerState<OurnegoOfflineBanner> createState() =>
      _OurnegoOfflineBannerState();
}

class _OurnegoOfflineBannerState extends ConsumerState<OurnegoOfflineBanner> {
  late _Phase _phase = ref.read(isOnlineProvider)
      ? _Phase.hidden
      : _Phase.offline;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onOnlineChanged(bool? previous, bool online) {
    _hideTimer?.cancel();
    if (!online) {
      setState(() => _phase = _Phase.offline);
      return;
    }
    if (previous == false) {
      setState(() => _phase = _Phase.restored);
      _hideTimer = Timer(OurnegoOfflineBanner.restoredFor, () {
        if (mounted) setState(() => _phase = _Phase.hidden);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isOnlineProvider, _onOnlineChanged);
    listenForReconnect(ref, () => refreshRemoteData(ref));

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: kStandardDuration,
            switchInCurve: kEaseOutCubic,
            switchOutCurve: kEaseOutCubic,
            transitionBuilder: (child, animation) => ClipRect(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _phase == _Phase.hidden
                ? const SizedBox.shrink(key: ValueKey('banner-hidden'))
                : _Banner(restored: _phase == _Phase.restored),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.restored});

  final bool restored;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const Key('offline-banner'),
      duration: kStandardDuration,
      curve: kEaseOutCubic,
      color: restored ? OurnegoColorTokens.success : OurnegoColorTokens.error,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnimatedSwitcher(
              duration: kFastDuration,
              child: Row(
                key: ValueKey(restored),
                children: [
                  Icon(
                    restored
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restored
                          ? 'Conexión restablecida'
                          : 'Sin conexión. Algunas funciones no estarán '
                                'disponibles.',
                      style: OurnegoTextStyles.bodyCompact.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
