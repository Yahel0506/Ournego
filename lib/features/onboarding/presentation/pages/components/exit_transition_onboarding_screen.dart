import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/onboarding/presentation/onboarding_flow_state.dart';

class ExitTransitionOnboardingScreen extends StatefulWidget {
  const ExitTransitionOnboardingScreen({
    super.key,
    required this.selectedRole,
    required this.onFinished,
  });

  final OnboardingUserRole selectedRole;
  final FutureOr<void> Function() onFinished;

  @override
  State<ExitTransitionOnboardingScreen> createState() =>
      _ExitTransitionOnboardingScreenState();
}

class _ExitTransitionOnboardingScreenState
    extends State<ExitTransitionOnboardingScreen> {
  static const Curve _entranceCurve = Cubic(0.22, 1, 0.36, 1);
  static const Duration _entranceDuration = Duration(milliseconds: 1000);

  Timer? _titleTimer;
  Timer? _descriptionTimer;
  Timer? _finishTimer;

  bool _showTitle = false;
  bool _showDescription = false;

  @override
  void initState() {
    super.initState();
    _startTimeline();
  }

  @override
  void didUpdateWidget(covariant ExitTransitionOnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRole != widget.selectedRole) {
      _resetTimeline();
      _startTimeline();
    }
  }

  void _startTimeline() {
    _titleTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _showTitle = true);
    });

    _descriptionTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showDescription = true);
    });

    _finishTimer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      widget.onFinished();
    });
  }

  void _resetTimeline() {
    _titleTimer?.cancel();
    _descriptionTimer?.cancel();
    _finishTimer?.cancel();
    _showTitle = false;
    _showDescription = false;
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    _descriptionTimer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.selectedRole) {
      OnboardingUserRole.discover => 'Ya hay lugares esperándote',
      OnboardingUserRole.business => 'Vamos a ayudarte a crecer',
    };

    final description = switch (widget.selectedRole) {
      OnboardingUserRole.discover => 'Explóralos ahora',
      OnboardingUserRole.business => 'Crea tu cuenta para empezar',
    };

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showTitle = reduceMotion || _showTitle;
    final showDescription = reduceMotion || _showDescription;
    final duration = reduceMotion ? Duration.zero : _entranceDuration;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSlide(
                  offset: showTitle ? Offset.zero : const Offset(0, 0.35),
                  duration: duration,
                  curve: _entranceCurve,
                  child: AnimatedOpacity(
                    opacity: showTitle ? 1 : 0,
                    duration: duration,
                    curve: _entranceCurve,
                    child: Text(
                      title,
                      style: OurnegoTextStyles.header,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSlide(
                  offset: showDescription ? Offset.zero : const Offset(0, 0.35),
                  duration: duration,
                  curve: _entranceCurve,
                  child: AnimatedOpacity(
                    opacity: showDescription ? 1 : 0,
                    duration: duration,
                    curve: _entranceCurve,
                    child: Text(
                      description,
                      style: OurnegoTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
