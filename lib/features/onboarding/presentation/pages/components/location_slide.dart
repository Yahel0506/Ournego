import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationSlide extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final String? buttonText;
  final VoidCallback onNext;
  final ValueChanged<PermissionStatus>? onPermissionStatusChanged;
  final Future<void> Function()? onPermissionRequired;

  const LocationSlide({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonText,
    required this.onNext,
    this.onPermissionStatusChanged,
    this.onPermissionRequired,
  });

  @override
  State<LocationSlide> createState() => _LocationSlideState();
}

class _LocationSlideState extends State<LocationSlide> {
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  bool get _isPermissionGranted => _permissionStatus.isGranted;

  @override
  void initState() {
    super.initState();
    _syncPermissionStatus();
  }

  Future<void> _syncPermissionStatus() async {
    final status = await Permission.location.status;

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = status;
    });
    widget.onPermissionStatusChanged?.call(status);
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = status;
    });
    widget.onPermissionStatusChanged?.call(status);

    if (status.isGranted) {
      widget.onNext();
    }
  }

  Future<void> _continue() async {
    if (_isPermissionGranted) {
      widget.onNext();
      return;
    }

    await widget.onPermissionRequired?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ------ Imágen ------
        SizedBox(
          height: 300,
          width: 300,
          child: Image(image: AssetImage(widget.imagePath)),
        ),
        SizedBox(height: 30),
        // ------ Titulo ------
        Text(
          widget.title,
          style: OurnegoTextStyles.header,
          textAlign: TextAlign.center,
        ),
        // ------ Descripción ------
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            widget.description,
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20),
        OutlinedButton(
          key: const ValueKey('activateLocationButton'),
          onPressed: _requestLocationPermission,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            side: BorderSide(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          child: Text(
            _isPermissionGranted ? 'UBICACION ACTIVADA' : 'ACTIVAR UBICACION',
            style: OurnegoTextStyles.body,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('onboardingLocationContinueButton'),
              onPressed: _continue,
              child: const Text('Continuar'),
            ),
          ),
        ),
        if (!_isPermissionGranted)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Debes habilitar la ubicacion para continuar.',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
