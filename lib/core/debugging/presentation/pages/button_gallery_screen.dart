import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// QA gallery of the Ournego button family (spec §12). Debug only, opened
/// from the debug panel. Mirrors the "Botones Ournego" playground.
class ButtonGalleryScreen extends StatefulWidget {
  const ButtonGalleryScreen({super.key});

  @override
  State<ButtonGalleryScreen> createState() => _ButtonGalleryScreenState();
}

enum _GalleryTheme { system, light, dark }

enum _PrimaryState { normal, pressed, disabled, loading, success }

class _ButtonGalleryScreenState extends State<ButtonGalleryScreen> {
  _GalleryTheme _theme = _GalleryTheme.system;
  bool _reducedMotion = false;

  ThemeData _resolveTheme(BuildContext context) {
    switch (_theme) {
      case _GalleryTheme.light:
        return OurnegoTheme.light;
      case _GalleryTheme.dark:
        return OurnegoTheme.dark;
      case _GalleryTheme.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? OurnegoTheme.dark
            : OurnegoTheme.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _resolveTheme(context);
    return Theme(
      data: theme,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: _reducedMotion),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(title: const Text('Galería de botones')),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
              children: [
                _header(context),
                const _PrimarySection(),
                const _SecondarySection(),
                const _AccessSection(),
                const _IconButtonsSection(),
                const _FlatGlassSection(),
                const _SheetSection(),
                const _ChipsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    const labels = {
      _GalleryTheme.system: 'Sistema',
      _GalleryTheme.light: 'Claro',
      _GalleryTheme.dark: 'Oscuro',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: OurnegoSpacingTokens.xs,
          runSpacing: OurnegoSpacingTokens.xs,
          children: [
            for (final entry in labels.entries)
              OurnegoChip.filter(
                label: entry.value,
                selected: _theme == entry.key,
                onSelected: (_) => setState(() => _theme = entry.key),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Simular reduced motion'),
          value: _reducedMotion,
          onChanged: (value) => setState(() => _reducedMotion = value),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: OurnegoSpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: OurnegoTextStyles.sheetTitle),
          const SizedBox(height: OurnegoSpacingTokens.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: OurnegoSpacingTokens.sm,
        bottom: OurnegoSpacingTokens.xs,
      ),
      child: Text(
        text,
        style: OurnegoTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Normal / Presionado / Apagado strip for one component.
class _StateStrip extends StatelessWidget {
  const _StateStrip({required this.builder});

  final Widget Function({required bool pressed, required bool enabled}) builder;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(right: OurnegoSpacingTokens.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: OurnegoSpacingTokens.xxs),
          Text(label, style: OurnegoTextStyles.caption),
        ],
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell('Normal', builder(pressed: false, enabled: true)),
          cell('Presionado', builder(pressed: true, enabled: true)),
          cell('Apagado', builder(pressed: false, enabled: false)),
        ],
      ),
    );
  }
}

void _noop() {}

class _PrimarySection extends StatefulWidget {
  const _PrimarySection();

  @override
  State<_PrimarySection> createState() => _PrimarySectionState();
}

class _PrimarySectionState extends State<_PrimarySection> {
  static const Duration _step = Duration(milliseconds: 1300);

  _PrimaryState _state = _PrimaryState.normal;
  OurnegoButtonStatus _flow = OurnegoButtonStatus.idle;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _runFlow() {
    setState(() => _flow = OurnegoButtonStatus.loading);
    _timer?.cancel();
    _timer = Timer(_step, () {
      if (!mounted) return;
      setState(() => _flow = OurnegoButtonStatus.success);
      _timer = Timer(_step, () {
        if (!mounted) return;
        setState(() => _flow = OurnegoButtonStatus.idle);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      _PrimaryState.normal: 'Normal',
      _PrimaryState.pressed: 'Presionado',
      _PrimaryState.disabled: 'Apagado',
      _PrimaryState.loading: 'Cargando',
      _PrimaryState.success: 'Listo',
    };
    final scheme = Theme.of(context).colorScheme;

    return _Section(
      title: 'Acción principal',
      children: [
        Wrap(
          spacing: OurnegoSpacingTokens.xs,
          runSpacing: OurnegoSpacingTokens.xs,
          children: [
            for (final entry in labels.entries)
              OurnegoChip.filter(
                label: entry.value,
                selected: _state == entry.key,
                onSelected: (_) => setState(() => _state = entry.key),
              ),
          ],
        ),
        const SizedBox(height: OurnegoSpacingTokens.md),
        OurnegoButton.primary(
          label: 'Iniciar sesión',
          expanded: true,
          showNego: true,
          forcePressed: _state == _PrimaryState.pressed,
          status: switch (_state) {
            _PrimaryState.loading => OurnegoButtonStatus.loading,
            _PrimaryState.success => OurnegoButtonStatus.success,
            _ => OurnegoButtonStatus.idle,
          },
          onPressed: _state == _PrimaryState.disabled ? null : _noop,
        ),
        const _Caption('Flujo: cargando 1300 ms → listo 1300 ms → normal'),
        OurnegoButton.primary(
          label: 'Registrar negocio',
          size: OurnegoButtonSize.large,
          expanded: true,
          showNego: true,
          status: _flow,
          onPressed: _flow == OurnegoButtonStatus.idle ? _runFlow : _noop,
        ),
        const _Caption('Neutro grande'),
        Center(
          child: OurnegoButton.neutral(
            label: 'Explorar',
            size: OurnegoButtonSize.large,
            minWidth: 200,
            trailingIcon: Icons.arrow_forward_rounded,
            iconMotion: OurnegoIconMotion.nudge,
            onPressed: _noop,
          ),
        ),
        const _Caption('Compactos'),
        Wrap(
          spacing: OurnegoSpacingTokens.sm,
          runSpacing: OurnegoSpacingTokens.sm,
          children: const [
            OurnegoButton.primary(
              label: 'Guardar',
              size: OurnegoButtonSize.compact,
              onPressed: _noop,
            ),
            OurnegoButton.primary(
              label: 'Reintentar',
              size: OurnegoButtonSize.compact,
              icon: Icons.refresh_rounded,
              iconMotion: OurnegoIconMotion.wiggle,
              onPressed: _noop,
            ),
          ],
        ),
        const SizedBox(height: OurnegoSpacingTokens.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OurnegoSpacingTokens.md,
            vertical: OurnegoSpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.innerCard),
            border: Border.all(
              color: OurnegoSemanticTokens.borderSubtle(scheme),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_disabled_rounded),
              const SizedBox(width: OurnegoSpacingTokens.sm),
              Expanded(
                child: Text(
                  'Ournego no puede ver tu ubicación',
                  style: OurnegoTextStyles.bodyCompact.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const OurnegoButton.primary(
                label: 'Permitir',
                size: OurnegoButtonSize.small,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondarySection extends StatelessWidget {
  const _SecondarySection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Section(
      title: 'Secundarios',
      children: [
        const _Caption('Secundario (con contorno)'),
        _StateStrip(
          builder: ({required pressed, required enabled}) =>
              OurnegoButton.secondary(
                label: 'Feedback',
                size: OurnegoButtonSize.compact,
                forcePressed: pressed,
                onPressed: enabled ? _noop : null,
              ),
        ),
        const _Caption('Texto'),
        _StateStrip(
          builder: ({required pressed, required enabled}) => OurnegoButton.text(
            label: 'Cancelar',
            size: OurnegoButtonSize.compact,
            forcePressed: pressed,
            onPressed: enabled ? _noop : null,
          ),
        ),
        const _Caption('Destructivo (mini diálogo)'),
        Container(
          padding: const EdgeInsets.all(OurnegoSpacingTokens.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.sheet),
            border: Border.all(
              color: OurnegoSemanticTokens.borderSubtle(scheme),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cerrar sesión', style: OurnegoTextStyles.title),
              const SizedBox(height: OurnegoSpacingTokens.xs),
              const Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: OurnegoTextStyles.bodyCompact,
              ),
              const SizedBox(height: OurnegoSpacingTokens.md),
              _StateStrip(
                builder: ({required pressed, required enabled}) =>
                    OurnegoButton.destructive(
                      label: 'Cerrar sesión',
                      size: OurnegoButtonSize.compact,
                      forcePressed: pressed,
                      onPressed: enabled ? _noop : null,
                    ),
              ),
            ],
          ),
        ),
        const _Caption('Tonal'),
        _StateStrip(
          builder: ({required pressed, required enabled}) =>
              OurnegoButton.tonal(
                label: 'Subir foto',
                size: OurnegoButtonSize.compact,
                icon: Icons.add_a_photo_rounded,
                iconMotion: OurnegoIconMotion.wiggle,
                forcePressed: pressed,
                onPressed: enabled ? _noop : null,
              ),
        ),
      ],
    );
  }
}

class _AccessSection extends StatelessWidget {
  const _AccessSection();

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: OurnegoSpacingTokens.sm);
    return _Section(
      title: 'Acceso',
      children: [
        OurnegoSocialButton.google(onPressed: _noop),
        gap,
        const OurnegoSocialButton(
          leading: Icon(Icons.mail_rounded),
          label: 'Continuar con correo',
          onPressed: _noop,
        ),
        gap,
        const OurnegoSocialButton(
          leading: Icon(Icons.call_rounded),
          label: 'Continuar con número telefónico',
          badge: 'Pronto',
          onPressed: null,
        ),
        gap,
        const OurnegoSocialButton(
          leading: Icon(Icons.person_rounded),
          label: 'Continuar como invitado',
          onPressed: _noop,
        ),
      ],
    );
  }
}

class _IconButtonsSection extends StatefulWidget {
  const _IconButtonsSection();

  @override
  State<_IconButtonsSection> createState() => _IconButtonsSectionState();
}

class _IconButtonsSectionState extends State<_IconButtonsSection> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: OurnegoSpacingTokens.xs);
    return _Section(
      title: 'Botones de icono',
      children: [
        const _Caption('Controles del mapa (radio 16, con labio)'),
        _StateStrip(
          builder: ({required pressed, required enabled}) => OurnegoIconButton(
            icon: Icons.add_rounded,
            semanticLabel: 'Acercar',
            radius: 16,
            forcePressed: pressed,
            onPressed: enabled ? _noop : null,
          ),
        ),
        const SizedBox(height: OurnegoSpacingTokens.xs),
        const Row(
          children: [
            OurnegoIconButton(
              icon: Icons.bug_report_rounded,
              semanticLabel: 'Depuración',
              radius: 16,
              onPressed: _noop,
            ),
            gap,
            OurnegoIconButton(
              icon: Icons.remove_rounded,
              semanticLabel: 'Alejar',
              radius: 16,
              onPressed: _noop,
            ),
            gap,
            OurnegoIconButton(
              icon: Icons.my_location_rounded,
              semanticLabel: 'Mi ubicación',
              radius: 16,
              onPressed: _noop,
            ),
          ],
        ),
        const _Caption('Controles del sheet (tonal con contorno, radio 14)'),
        Row(
          children: [
            const OurnegoIconButton(
              tone: OurnegoButtonTone.tonal,
              outlined: true,
              size: OurnegoIconButtonSize.s32,
              radius: 14,
              icon: Icons.share_rounded,
              semanticLabel: 'Compartir',
              onPressed: _noop,
            ),
            gap,
            OurnegoIconButton.toggle(
              outlined: true,
              radius: 14,
              selected: _favorite,
              icon: Icons.favorite_border_rounded,
              selectedIcon: Icons.favorite_rounded,
              celebrate: true,
              semanticLabel: 'Favorito',
              onChanged: (value) => setState(() => _favorite = value),
            ),
            gap,
            const OurnegoIconButton(
              tone: OurnegoButtonTone.tonal,
              outlined: true,
              size: OurnegoIconButtonSize.s32,
              radius: 14,
              icon: Icons.picture_in_picture_alt_rounded,
              semanticLabel: 'Minimizar',
              onPressed: _noop,
            ),
            gap,
            const OurnegoIconButton(
              tone: OurnegoButtonTone.tonal,
              outlined: true,
              size: OurnegoIconButtonSize.s32,
              radius: 14,
              icon: Icons.open_in_full_rounded,
              semanticLabel: 'Expandir',
              onPressed: _noop,
            ),
          ],
        ),
        const _Caption('Iconos del panel (44 y 28)'),
        const Row(
          children: [
            OurnegoIconButton(
              size: OurnegoIconButtonSize.s44,
              icon: Icons.account_circle_rounded,
              semanticLabel: 'Perfil',
              onPressed: _noop,
            ),
            gap,
            OurnegoIconButton(
              tone: OurnegoButtonTone.primary,
              size: OurnegoIconButtonSize.s44,
              icon: Icons.edit_rounded,
              semanticLabel: 'Cambiar foto de perfil',
              onPressed: _noop,
            ),
            gap,
            OurnegoIconButton(
              size: OurnegoIconButtonSize.s28,
              icon: Icons.edit_rounded,
              semanticLabel: 'Editar',
              onPressed: _noop,
            ),
            gap,
            OurnegoIconButton(
              size: OurnegoIconButtonSize.s28,
              icon: Icons.delete_outline_rounded,
              semanticLabel: 'Eliminar imagen',
              onPressed: _noop,
            ),
          ],
        ),
        const _Caption('Regresar'),
        const Row(
          children: [
            OurnegoIconButton.ghost(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Regresar',
              tooltip: 'Regresar',
              onPressed: _noop,
            ),
          ],
        ),
      ],
    );
  }
}

class _FlatGlassSection extends StatefulWidget {
  const _FlatGlassSection();

  @override
  State<_FlatGlassSection> createState() => _FlatGlassSectionState();
}

class _FlatGlassSectionState extends State<_FlatGlassSection> {
  bool _listening = false;
  int _navIndex = 1;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Fake map so the blur is visible.
    final mapColors = dark
        ? const [Color(0xFF243330), Color(0xFF1B2A3A), Color(0xFF2E2A22)]
        : const [Color(0xFFE6F2EC), Color(0xFFD4ECF7), Color(0xFFF3EBD9)];

    return _Section(
      title: 'Flat glass',
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.sheet),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: mapColors,
            ),
          ),
          padding: const EdgeInsets.all(OurnegoSpacingTokens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  OurnegoGlassIconButton(
                    icon: Icons.mic_none_rounded,
                    activeIcon: Icons.mic_rounded,
                    active: _listening,
                    showHalo: true,
                    semanticLabel: _listening
                        ? 'Detener búsqueda por voz'
                        : 'Buscar por voz',
                    onPressed: () => setState(() => _listening = !_listening),
                  ),
                  const SizedBox(width: OurnegoSpacingTokens.controlGap),
                  Expanded(
                    child: OurnegoGlassSurface(
                      child: SearchBar(
                        hintText: 'Buscar negocio...',
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: const WidgetStatePropertyAll(
                          Color(0x00000000),
                        ),
                        leading: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: OurnegoGlassSurfaceIcon(Icons.search_rounded),
                        ),
                        constraints: const BoxConstraints(minHeight: 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: OurnegoSpacingTokens.controlGap),
                  const OurnegoGlassIconButton(
                    icon: Icons.account_circle_rounded,
                    semanticLabel: 'Abrir menú de perfil',
                    onPressed: _noop,
                  ),
                ],
              ),
              const SizedBox(height: OurnegoSpacingTokens.md),
              const Center(
                child: OurnegoGlassChip(
                  label: 'Zona: Col. Centro',
                  actionLabel: 'Cambiar',
                  semanticLabel: 'Zona: Col. Centro. Cambiar',
                  onPressed: _noop,
                ),
              ),
              const SizedBox(height: OurnegoSpacingTokens.lg),
              OurnegoNavBar(
                items: const [
                  OurnegoNavBarItem(
                    icon: Icons.people_rounded,
                    label: 'Inicio',
                  ),
                  OurnegoNavBarItem(
                    icon: Icons.location_on_rounded,
                    label: 'Mapa',
                  ),
                  OurnegoNavBarItem(
                    icon: Icons.store_rounded,
                    label: 'Mi Negocio',
                  ),
                ],
                currentIndex: _navIndex,
                onTap: (index) => setState(() => _navIndex = index),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetSection extends StatefulWidget {
  const _SheetSection();

  @override
  State<_SheetSection> createState() => _SheetSectionState();
}

class _SheetSectionState extends State<_SheetSection> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: OurnegoSpacingTokens.xs);
    return _Section(
      title: 'Floating sheet',
      children: [
        const _Caption('Acciones de icono'),
        const Row(
          children: [
            Expanded(
              child: OurnegoActionButton(
                icon: Icons.sentiment_satisfied_rounded,
                semanticLabel: 'Reseñas',
                onPressed: _noop,
              ),
            ),
            gap,
            Expanded(
              child: OurnegoActionButton(
                icon: Icons.search_rounded,
                semanticLabel: 'Catálogo',
                onPressed: _noop,
              ),
            ),
            gap,
            Expanded(
              child: OurnegoActionButton(
                icon: Icons.chat_rounded,
                semanticLabel: 'Mensaje',
                onPressed: _noop,
              ),
            ),
          ],
        ),
        const _Caption('Fila'),
        const OurnegoRowButton(
          icon: Icons.sentiment_satisfied_rounded,
          label: 'Opinión general',
          onPressed: _noop,
        ),
        const _Caption('Acción con texto'),
        const Wrap(
          spacing: OurnegoSpacingTokens.sm,
          runSpacing: OurnegoSpacingTokens.sm,
          children: [
            OurnegoButton.secondary(
              label: 'Mensaje',
              size: OurnegoButtonSize.compact,
              radius: 14,
              icon: Icons.chat_rounded,
              iconMotion: OurnegoIconMotion.wiggle,
              onPressed: _noop,
            ),
            OurnegoButton.secondary(
              label: 'Llamar',
              size: OurnegoButtonSize.compact,
              radius: 14,
              icon: Icons.call_rounded,
              iconMotion: OurnegoIconMotion.wiggle,
              onPressed: _noop,
            ),
            OurnegoButton.text(
              label: 'Ver catálogo',
              size: OurnegoButtonSize.compact,
              icon: Icons.inventory_2_rounded,
              iconMotion: OurnegoIconMotion.wiggle,
              onPressed: _noop,
            ),
          ],
        ),
        const _Caption('Tiles'),
        Row(
          children: [
            Expanded(
              child: OurnegoActionTile(
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                label: 'Favorito',
                selected: _favorite,
                celebrate: true,
                onPressed: () => setState(() => _favorite = !_favorite),
              ),
            ),
            gap,
            const Expanded(
              child: OurnegoActionTile(
                icon: Icons.share_rounded,
                label: 'Compartir',
                onPressed: _noop,
              ),
            ),
            gap,
            const Expanded(
              child: OurnegoActionTile(
                icon: Icons.call_rounded,
                label: 'Llamar',
                onPressed: _noop,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipsSection extends StatefulWidget {
  const _ChipsSection();

  @override
  State<_ChipsSection> createState() => _ChipsSectionState();
}

class _ChipsSectionState extends State<_ChipsSection> {
  bool _openNow = false;
  String? _category;
  double? _distance;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Chips',
      children: [
        Row(
          children: [
            OurnegoChip.filter(
              label: 'Abiertos',
              selected: _openNow,
              onSelected: (value) => setState(() => _openNow = value),
            ),
            const SizedBox(width: OurnegoSpacingTokens.xs),
            Expanded(
              child: OurnegoChip<String?>.dropdown(
                placeholder: 'Categoría',
                value: _category,
                options: const [
                  OurnegoChipOption(value: null, label: 'Todas'),
                  OurnegoChipOption(value: 'food', label: 'Comida'),
                  OurnegoChipOption(value: 'shop', label: 'Tiendas'),
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
            ),
            const SizedBox(width: OurnegoSpacingTokens.xs),
            Expanded(
              child: OurnegoChip<double?>.dropdown(
                placeholder: 'Distancia',
                value: _distance,
                options: const [
                  OurnegoChipOption(value: null, label: 'Sin límite'),
                  OurnegoChipOption(value: 1000, label: '1 km'),
                  OurnegoChipOption(value: 5000, label: '5 km'),
                ],
                onChanged: (value) => setState(() => _distance = value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
