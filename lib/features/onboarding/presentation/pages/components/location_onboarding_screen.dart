import 'package:flutter/material.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/onboarding_responsive_layout.dart';
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
  final Future<void> Function(PermissionStatus status)? onPermissionRequired;

  @override
  State<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState extends State<LocationOnboardingScreen>
    with WidgetsBindingObserver {
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  bool get _isPermissionGranted => _permissionStatus.isGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionStatus();
    }
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
      return;
    }

    await widget.onPermissionRequired?.call(status);
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final iconSize = (screenHeight * 0.22).clamp(120.0, 180.0).toDouble();

    return OnboardingResponsiveLayout(
      padding: const EdgeInsets.all(48),
      scrollBelowHeight: 700,
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
          Icon(
            Icons.location_on,
            size: iconSize,
            color: OurnegoColorTokens.warning,
          ),
          const Spacer(),
          if (!_isPermissionGranted)
            const Text(
              'Debes habilitar la ubicacion para continuar.',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
