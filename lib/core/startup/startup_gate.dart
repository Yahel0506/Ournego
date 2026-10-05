import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/startup/startup_controller.dart';

typedef StartupAppBuilder = Widget Function(bool startOnMap);
typedef StartupSupportLauncher = Future<bool> Function(Uri uri);

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.controller,
    required this.appBuilder,
    this.supportLauncher = _launchSupport,
  });

  final StartupController controller;
  final StartupAppBuilder appBuilder;
  final StartupSupportLauncher supportLauncher;

  static Future<bool> _launchSupport(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.start();
  }

  @override
  void didUpdateWidget(covariant StartupGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.dispose();
      widget.controller.addListener(_onControllerChanged);
      widget.controller.start();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    if (state.isReady) return widget.appBuilder(state.startOnMap);
    return MaterialApp(
      title: 'Ournego',
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
      home: _StartupStatusScreen(
        state: state,
        onRetry: widget.controller.retry,
        supportLauncher: widget.supportLauncher,
      ),
    );
  }
}

class _StartupStatusScreen extends StatefulWidget {
  const _StartupStatusScreen({
    required this.state,
    required this.onRetry,
    required this.supportLauncher,
  });

  final StartupState state;
  final VoidCallback onRetry;
  final StartupSupportLauncher supportLauncher;

  @override
  State<_StartupStatusScreen> createState() => _StartupStatusScreenState();
}

class _StartupStatusScreenState extends State<_StartupStatusScreen> {
  bool _couldNotOpenSupport = false;

  Future<void> _showHelp() async {
    final failure = widget.state.failure;
    final body = switch (failure?.kind) {
      StartupErrorKind.configuration =>
        'Esta instalación necesita una corrección. Actualiza Ournego o contacta al equipo de soporte.',
      StartupErrorKind.preparation =>
        'Ournego no pudo preparar un servicio local. Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, contacta al equipo de soporte.',
      StartupErrorKind.initialization =>
        'Ournego no terminó de iniciar. Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, contacta al equipo de soporte.',
      StartupErrorKind.timeout =>
        'El inicio tardó demasiado. Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, contacta al equipo de soporte.',
      null => 'Espera un momento mientras preparamos Ournego.',
    };

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ayuda para iniciar Ournego'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(body),
                if (_couldNotOpenSupport) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'No pudimos abrir el canal de consultas. Puedes volver a intentarlo más tarde.',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                var opened = false;
                try {
                  opened = await widget.supportLauncher(
                    Uri.parse('https://wa.me/3411768237'),
                  );
                } catch (_) {
                  opened = false;
                }
                if (!opened && context.mounted) {
                  setDialogState(() => _couldNotOpenSupport = true);
                }
              },
              child: const Text('Contactar soporte'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = widget.state.failure;
    final isStarting = widget.state.isStarting;
    final title = isStarting
        ? 'Preparando Ournego'
        : failure?.kind == StartupErrorKind.configuration
        ? 'Ournego no puede iniciar'
        : 'No pudimos iniciar Ournego';
    final explanation = isStarting
        ? 'Estamos preparando la aplicación.'
        : failure?.kind == StartupErrorKind.configuration
        ? 'Esta instalación necesita una corrección para funcionar.'
        : failure?.canRetry == true
        ? 'Puedes intentar iniciar una vez más.'
        : 'Cierra Ournego por completo y vuelve a abrirla. Si el problema continúa, consulta la ayuda.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isStarting ? Icons.hourglass_top : Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    explanation,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (isStarting) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                  if (failure != null) ...[
                    const SizedBox(height: 24),
                    if (failure.canRetry)
                      FilledButton.icon(
                        onPressed: widget.onRetry,
                        style: FilledButton.styleFrom(
                          foregroundColor: OurnegoColors.noche,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _showHelp,
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Ver ayuda'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
