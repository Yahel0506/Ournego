import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/models/location_editor_result.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';

class LocationEditorDialog extends StatefulWidget {
  const LocationEditorDialog({
    super.key,
    required this.initialAddress,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  final String initialAddress;
  final double initialLatitude;
  final double initialLongitude;

  @override
  State<LocationEditorDialog> createState() => _LocationEditorDialogState();
}

class _LocationEditorDialogState extends State<LocationEditorDialog>
    with TickerProviderStateMixin {
  late final TextEditingController _addressController;
  late final AnimatedMapController _mapController;
  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _mapController = AnimatedMapController(vsync: this);
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = MapboxConfig.accessToken;
    final hasMapbox = token.isNotEmpty;
    return AlertDialog(
      title: const Text('Editar ubicacion'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OurnegoInputField(
              controller: _addressController,
              labelText: 'Direccion',
              maxLines: 2,
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            SizedBox(
              height: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
                child: FlutterMap(
                  mapController: _mapController.mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_latitude, _longitude),
                    initialZoom: 16,
                    maxZoom: 18,
                    minZoom: 3,
                    onPositionChanged: (camera, hasGesture) {
                      setState(() {
                        _latitude = camera.center.latitude;
                        _longitude = camera.center.longitude;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: hasMapbox
                          ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=$token'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ournego.app',
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.location_on,
                            size: 42,
                            color: OurnegoColorTokens.warning,
                          ),
                          SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OurnegoButton.text(
          size: OurnegoButtonSize.compact,
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        OurnegoButton.primary(
          size: OurnegoButtonSize.compact,
          label: 'Guardar',
          onPressed: () {
            Navigator.of(context).pop(
              LocationEditorResult(
                address: _addressController.text.trim(),
                latitude: _latitude,
                longitude: _longitude,
              ),
            );
          },
        ),
      ],
    );
  }
}
