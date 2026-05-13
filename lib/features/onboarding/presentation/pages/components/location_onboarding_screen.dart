import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationOnboardingScreen extends StatefulWidget {
  const LocationOnboardingScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onNext,
    this.onPermissionStatusChanged,
    this.onPermissionRequired,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNext;
  final ValueChanged<PermissionStatus>? onPermissionStatusChanged;
  final Future<void> Function()? onPermissionRequired;

  @override
  State<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState extends State<LocationOnboardingScreen> {
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  bool get _isPermissionGranted => _permissionStatus.isGranted;

  @override
  void initState() {
    super.initState();
    _syncPermissionStatus();
  }

  Future<void> _syncPermissionStatus() async {
    final status = await Permission.location.status;
    if (!mounted) return;

    setState(() => _permissionStatus = status);
    widget.onPermissionStatusChanged?.call(status);
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!mounted) return;

    setState(() => _permissionStatus = status);
    widget.onPermissionStatusChanged?.call(status);

    if (status.isGranted) {
      widget.onNext();
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_isPermissionGranted) {
      widget.onNext();
      return;
    }
    await _requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 72),
          Text(
            widget.title,
            style: OurnegoTextStyles.onboardingHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.subtitle,
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            height: 60,
            child: OurnegoPrimaryButton(
              key: const ValueKey('activateLocationButton'),
              onPressed: _onPrimaryAction,
              child: Text(
                _isPermissionGranted ? 'Continuar' : 'Activar',
                style: OurnegoTextStyles.header,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Icon(Icons.location_on, size: 180, color: Colors.redAccent),
          if (!_isPermissionGranted)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Debes habilitar la ubicacion para continuar.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
