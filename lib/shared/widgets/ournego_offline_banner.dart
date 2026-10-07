import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/network/connectivity_providers.dart';
import 'package:ournego/core/network/reconnect_refresh.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

/// Wraps the app and shows a persistent banner while the device is offline.
/// On reconnection it reloads remote data that may have failed.
class OurnegoOfflineBanner extends ConsumerWidget {
  const OurnegoOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    listenForReconnect(ref, () {
      refreshRemoteData(ref);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Conexión restablecida')));
    });

    return Column(
      children: [
        if (!isOnline)
          Material(
            key: const Key('offline-banner'),
            color: OurnegoColorTokens.error,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sin conexión. Algunas funciones no estarán disponibles.',
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
        Expanded(child: child),
      ],
    );
  }
}
