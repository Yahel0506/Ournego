import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';

enum LocationAccessSheetAction {
  allow,
  chooseZone,
  openSettings,
  continueWithoutLocation,
}

/// Content where Nego explains why Ournego needs the location. When the
/// permission can be asked again it offers to grant it or to continue without
/// it; when it was blocked for good it offers to pick a zone or open settings.
///
/// It is a page of the location flow sheet (`showLocationFlowSheet`).
class LocationAccessSheet extends StatelessWidget {
  const LocationAccessSheet({super.key, required this.status, this.onAction});

  /// Called with the chosen action instead of closing the route, when the
  /// sheet is part of a flow that decides what happens next.
  final ValueChanged<LocationAccessSheetAction>? onAction;

  /// Either [LocationAccessStatus.permissionDenied] (can be asked again) or
  /// [LocationAccessStatus.permissionDeniedForever] (settings only).
  final LocationAccessStatus status;

  bool get _isPermanent =>
      status == LocationAccessStatus.permissionDeniedForever;

  void _choose(BuildContext context, LocationAccessSheetAction action) {
    final callback = onAction;
    if (callback != null) {
      callback(action);
    } else {
      Navigator.of(context).pop(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _isPermanent
        ? 'Bloqueaste el permiso de ubicación. Elige tu zona para seguir '
              'explorando, o actívalo desde los ajustes.'
        : '¡Hola! Necesito tu ubicación para mostrarte los negocios que '
              'tienes cerca de ti.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OurnegoSpacingTokens.lg,
          OurnegoSpacingTokens.xxs,
          OurnegoSpacingTokens.lg,
          OurnegoSpacingTokens.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NegoSpeechBubble(
              key: const Key('location-access-nego'),
              message: message,
              mood: _isPermanent ? NegoMood.idle : NegoMood.excited,
            ),
            const SizedBox(height: OurnegoSpacingTokens.lg),
            OurnegoButton.primary(
              key: const Key('location-access-primary'),
              expanded: true,
              label: _isPermanent ? 'Elegir mi zona' : 'Permitir',
              onPressed: () => _choose(
                context,
                _isPermanent
                    ? LocationAccessSheetAction.chooseZone
                    : LocationAccessSheetAction.allow,
              ),
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            OurnegoButton.secondary(
              key: const Key('location-access-secondary'),
              expanded: true,
              label: _isPermanent
                  ? (kIsWeb ? 'Cómo activarla' : 'Abrir ajustes')
                  : 'Continuar sin ubicación',
              onPressed: () => _choose(
                context,
                _isPermanent
                    ? LocationAccessSheetAction.openSettings
                    : LocationAccessSheetAction.continueWithoutLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
