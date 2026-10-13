import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

class MapControlsWidget extends StatelessWidget {
  final bool showDebugButton;
  final Future<void> Function() onDebugTap;
  final Future<void> Function() onZoomInTap;
  final Future<void> Function() onZoomOutTap;
  final Future<void> Function() onMyLocationTap;
  final bool hasLocationAccess;

  const MapControlsWidget({
    super.key,
    required this.showDebugButton,
    required this.onDebugTap,
    required this.onZoomInTap,
    required this.onZoomOutTap,
    required this.onMyLocationTap,
    this.hasLocationAccess = true,
  });

  // Map controls are action buttons: they keep the lip even over the map.
  Widget _control({
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
  }) {
    return OurnegoIconButton(
      tone: OurnegoButtonTone.glass,
      size: OurnegoIconButtonSize.s52,
      radius: 16,
      icon: icon,
      semanticLabel: label,
      onPressed: () {
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: OurnegoSpacingTokens.xs);
    return Column(
      children: [
        if (showDebugButton) ...[
          _control(
            icon: Icons.bug_report_rounded,
            label: 'Depuración',
            onTap: onDebugTap,
          ),
          gap,
        ],
        _control(icon: Icons.add_rounded, label: 'Acercar', onTap: onZoomInTap),
        gap,
        _control(
          icon: Icons.remove_rounded,
          label: 'Alejar',
          onTap: onZoomOutTap,
        ),
        gap,
        _control(
          icon: hasLocationAccess
              ? Icons.my_location_rounded
              : Icons.location_disabled_rounded,
          label: 'Mi ubicación',
          onTap: onMyLocationTap,
        ),
      ],
    );
  }
}
