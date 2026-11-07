import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// Tells the user the businesses on the map are the last ones loaded and may
/// be out of date. They refresh by themselves when the network returns; the
/// action does it right away.
class MapStaleBusinessesChip extends StatelessWidget {
  const MapStaleBusinessesChip({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: OurnegoGlassChip(
        key: const Key('stale-businesses-chip'),
        leadingIcon: Icons.history_rounded,
        label: 'Negocios desactualizados',
        actionLabel: 'Actualizar',
        semanticLabel: 'Negocios desactualizados. Actualizar',
        onPressed: onRefresh,
      ),
    );
  }
}
