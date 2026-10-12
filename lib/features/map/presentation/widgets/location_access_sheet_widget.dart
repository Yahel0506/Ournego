import 'package:flutter/material.dart';

import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';

enum LocationAccessSheetAction { allow, openSettings, continueWithoutLocation }

/// Bottom sheet where Nego explains why Ournego needs the location and offers
/// to grant it or to keep going without it.
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
        ? 'Bloqueaste el permiso de ubicación. Actívalo desde los ajustes '
              'para ver los negocios que tienes cerca.'
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
            FilledButton(
              key: const Key('location-access-primary'),
              onPressed: () => Navigator.of(context).pop(
                _isPermanent
                    ? LocationAccessSheetAction.openSettings
                    : LocationAccessSheetAction.allow,
              ),
              child: Text(_isPermanent ? 'Abrir ajustes' : 'Permitir'),
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            OutlinedButton(
              key: const Key('location-access-continue'),
              onPressed: () => Navigator.of(
                context,
              ).pop(LocationAccessSheetAction.continueWithoutLocation),
              child: const Text('Continuar sin ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}
