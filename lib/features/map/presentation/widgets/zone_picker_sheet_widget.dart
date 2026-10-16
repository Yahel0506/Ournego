import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/entities/reference_location.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

sealed class ZonePickerResult {
  const ZonePickerResult();
}

class ZonePicked extends ZonePickerResult {
  final ManualZone zone;
  const ZonePicked(this.zone);
}

class ZoneCleared extends ZonePickerResult {
  const ZoneCleared();
}

/// Lets the user choose the zone used instead of the device location, either
/// by searching for a neighbourhood/street or by taking the map's center.
///
/// Returns null when dismissed.
Future<ZonePickerResult?> showZonePickerSheet(
  BuildContext context, {
  required AppPosition mapCenter,
  ManualZone? currentZone,
}) {
  return showOurnegoSheet<ZonePickerResult>(
    context: context,
    useRootNavigator: true,
    builder: (_) =>
        ZonePickerSheet(mapCenter: mapCenter, currentZone: currentZone),
  );
}

enum _SearchStatus { idle, loading, results, empty, offline, failed }

class ZonePickerSheet extends ConsumerStatefulWidget {
  const ZonePickerSheet({
    super.key,
    required this.mapCenter,
    this.currentZone,
    this.debounce = const Duration(milliseconds: 400),
    this.onResult,
  });

  final AppPosition mapCenter;
  final ManualZone? currentZone;
  final Duration debounce;

  /// Called with the result instead of closing the route, when the sheet is
  /// part of a flow that decides what happens next.
  final ValueChanged<ZonePickerResult>? onResult;

  @override
  ConsumerState<ZonePickerSheet> createState() => _ZonePickerSheetState();
}

class _ZonePickerSheetState extends ConsumerState<ZonePickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  int _requestId = 0;

  _SearchStatus _status = _SearchStatus.idle;
  List<ManualZone> _results = const [];
  bool _isResolvingCenter = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    final query = value.trim();
    // Ignore whatever is still on its way for the previous text.
    final requestId = ++_requestId;

    if (query.length < 3) {
      setState(() {
        _status = _SearchStatus.idle;
        _results = const [];
      });
      return;
    }

    setState(() => _status = _SearchStatus.loading);
    _debounceTimer = Timer(widget.debounce, () => _search(query, requestId));
  }

  Future<void> _search(String query, int requestId) async {
    final result = await ref.read(searchZoneSuggestionsUsecaseProvider)(query);
    if (!mounted || requestId != _requestId) return;

    result.fold(
      (failure) => setState(() {
        _results = const [];
        _status = failure is NetworkFailure
            ? _SearchStatus.offline
            : _SearchStatus.failed;
      }),
      (zones) => setState(() {
        _results = zones;
        _status = zones.isEmpty ? _SearchStatus.empty : _SearchStatus.results;
      }),
    );
  }

  Future<void> _useMapCenter() async {
    if (_isResolvingCenter) return;
    setState(() => _isResolvingCenter = true);
    final zone = await ref.read(resolveZoneFromPointUsecaseProvider)(
      widget.mapCenter,
    );
    if (!mounted) return;
    _finish(ZonePicked(zone));
  }

  void _finish(ZonePickerResult result) {
    final callback = widget.onResult;
    if (callback != null) {
      callback(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              OurnegoSpacingTokens.lg,
              0,
              OurnegoSpacingTokens.lg,
              OurnegoSpacingTokens.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Dónde quieres explorar?',
                  style: OurnegoTextStyles.title,
                ),
                const SizedBox(height: OurnegoSpacingTokens.xxs),
                Text(
                  'Usaremos esta zona para centrar el mapa y calcular '
                  'distancias.',
                  style: OurnegoTextStyles.bodyCompact.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: OurnegoSpacingTokens.md),
                TextField(
                  key: const Key('zone-picker-field'),
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Busca tu colonia o calle',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: OurnegoSpacingTokens.xs),
                ListTile(
                  key: const Key('zone-picker-use-map-center'),
                  contentPadding: EdgeInsets.zero,
                  leading: _isResolvingCenter
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.center_focus_strong_rounded),
                  title: const Text('Usar el centro del mapa'),
                  onTap: _useMapCenter,
                ),
                if (widget.currentZone != null)
                  ListTile(
                    key: const Key('zone-picker-clear'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: Text(
                      'Volver a ${ReferenceLocation.defaultZone.label}',
                    ),
                    onTap: () => _finish(const ZoneCleared()),
                  ),
                const Divider(height: OurnegoSpacingTokens.md),
                // Loose: the sheet is as tall as its content, not as the space.
                Flexible(fit: FlexFit.loose, child: _buildResults(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hintStyle = OurnegoTextStyles.bodyCompact.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    );

    switch (_status) {
      case _SearchStatus.idle:
        return Text('Escribe al menos 3 letras para buscar.', style: hintStyle);
      case _SearchStatus.loading:
        return const Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(OurnegoSpacingTokens.xs),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case _SearchStatus.empty:
        return Text(
          'No encontramos esa zona. Prueba con otro nombre o usa el centro '
          'del mapa.',
          key: const Key('zone-picker-empty'),
          style: hintStyle,
        );
      case _SearchStatus.offline:
        return Text(
          'Sin conexión. Puedes usar el centro del mapa mientras tanto.',
          key: const Key('zone-picker-offline'),
          style: hintStyle,
        );
      case _SearchStatus.failed:
        return Text(
          'No pudimos buscar ahora. Inténtalo de nuevo o usa el centro del '
          'mapa.',
          key: const Key('zone-picker-failed'),
          style: hintStyle,
        );
      case _SearchStatus.results:
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final zone = _results[index];
            return ListTile(
              key: ValueKey('zone-suggestion-$index'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(
                zone.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _finish(ZonePicked(zone)),
            );
          },
        );
    }
  }
}
