import 'package:flutter/material.dart';

import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';

enum LocationAccessSheetAction {
  allow,
  chooseZone,
  openSettings,
  continueWithoutLocation,
}

/// Bottom sheet where Nego explains why Ournego needs the location. When the
/// permission can be asked again it offers to grant it or to continue without
/// it; when it was blocked for good it offers to pick a zone or open settings.
///
/// Returns the chosen action, or null if the user dismissed the sheet.
Future<LocationAccessSheetAction?> showLocationAccessSheet(
  BuildContext context, {
  required LocationAccessStatus status,
}) {
  return showModalBottomSheet<LocationAccessSheetAction>(
    context: context,
    // Above the map's bottom navigation, which would otherwise cover it.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(OurnegoRadiusTokens.window),
      ),
    ),
    builder: (_) => LocationAccessSheet(status: status),
  );
}

class LocationAccessSheet extends StatelessWidget {
  const LocationAccessSheet({super.key, required this.status});

  /// Either [LocationAccessStatus.permissionDenied] (can be asked again) or
  /// [LocationAccessStatus.permissionDeniedForever] (settings only).
  final LocationAccessStatus status;

  bool get _isPermanent =>
      status == LocationAccessStatus.permissionDeniedForever;

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
              onPressed: () => Navigator.of(context).pop(
                _isPermanent
                    ? LocationAccessSheetAction.chooseZone
                    : LocationAccessSheetAction.allow,
              ),
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            OurnegoButton.secondary(
              key: const Key('location-access-secondary'),
              expanded: true,
              label: _isPermanent ? 'Abrir ajustes' : 'Continuar sin ubicación',
              onPressed: () => Navigator.of(context).pop(
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
