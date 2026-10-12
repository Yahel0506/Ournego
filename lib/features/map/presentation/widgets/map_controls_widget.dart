import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDebugButton) ...[
          _MapControlButton(icon: Icons.bug_report, onPressed: onDebugTap),
          const SizedBox(height: 12),
        ],
        _MapControlButton(icon: Icons.add, onPressed: onZoomInTap),
        const SizedBox(height: 12),
        _MapControlButton(icon: Icons.remove, onPressed: onZoomOutTap),
        const SizedBox(height: 12),
        _MapControlButton(
          icon: hasLocationAccess
              ? Icons.my_location_rounded
              : Icons.location_disabled_rounded,
          onPressed: onMyLocationTap,
        ),
      ],
    );
  }
}

class _MapControlButton extends StatefulWidget {
  final IconData icon;
  final Future<void> Function() onPressed;

  const _MapControlButton({required this.icon, required this.onPressed});

  @override
  State<_MapControlButton> createState() => _MapControlButtonState();
}

class _MapControlButtonState extends State<_MapControlButton> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    if (!mounted) return;
    setState(() {
      _isPressed = true;
    });

    await widget.onPressed();

    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _isPressed ? 0.94 : 1,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _handleTap,
            child: Icon(widget.icon, size: 22, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
