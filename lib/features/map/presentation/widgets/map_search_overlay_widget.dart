import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/controllers/search_businesses_usecase.dart';
import 'package:ournego/features/map/presentation/mappers/business_marker_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// The panel's content. Its frame and position belong to `SearchMorphSurface`,
/// which lays this widget out at its final size.
class MapSearchOverlayWidget extends StatelessWidget {
  final List<MapSearchResult> results;
  final String query;
  final bool hasData;
  final AppPosition? location;

  /// Name of the zone distances are measured from when there is no GPS fix.
  final String? referenceLabel;
  final MapSearchFilters filters;
  final List<BusinessType> categoryOptions;
  final List<double> distanceOptionsMeters;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final ValueChanged<bool> onOpenNowChanged;
  final ValueChanged<BusinessType?> onCategoryChanged;
  final ValueChanged<double?> onDistanceChanged;

  /// [origin] is the tapped row's rectangle in global coordinates.
  final void Function(Business business, Rect origin) onBusinessSelected;

  const MapSearchOverlayWidget({
    super.key,
    required this.results,
    required this.query,
    required this.hasData,
    required this.location,
    this.referenceLabel,
    required this.filters,
    required this.categoryOptions,
    required this.distanceOptionsMeters,
    required this.onClear,
    required this.onClose,
    required this.onOpenNowChanged,
    required this.onCategoryChanged,
    required this.onDistanceChanged,
    required this.onBusinessSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedQuery = query.trim();
    final markerUiMapper = BusinessMarkerUiMapper();

    Widget body;
    String bodyState;
    if (trimmedQuery.isEmpty) {
      bodyState = 'idle';
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Escribe para buscar negocios por nombre, categoria o direccion.',
          style: OurnegoTextStyles.body.copyWith(fontSize: 14),
        ),
      );
    } else if (!hasData) {
      bodyState = 'loading';
      body = const Padding(
        padding: EdgeInsets.all(14),
        child: LinearProgressIndicator(minHeight: 2),
      );
    } else if (results.isEmpty) {
      bodyState = 'empty';
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'No encontramos coincidencias para "$trimmedQuery".',
          style: OurnegoTextStyles.body.copyWith(fontSize: 14),
        ),
      );
    } else {
      bodyState = 'results';
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                OurnegoChip.filter(
                  label: 'Abiertos',
                  selected: filters.onlyOpenNow,
                  onSelected: onOpenNowChanged,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OurnegoChip<BusinessType?>.dropdown(
                    placeholder: 'Categoría',
                    value: filters.category,
                    options: [
                      const OurnegoChipOption<BusinessType?>(
                        value: null,
                        label: 'Todas',
                      ),
                      ...categoryOptions.map(
                        (type) => OurnegoChipOption<BusinessType?>(
                          value: type,
                          label: businessTypeLabel(type),
                        ),
                      ),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OurnegoChip<double?>.dropdown(
                    placeholder: 'Distancia',
                    value: filters.maxDistanceMeters,
                    options: [
                      const OurnegoChipOption<double?>(
                        value: null,
                        label: 'Sin límite',
                      ),
                      ...distanceOptionsMeters.map(
                        (distanceMeters) => OurnegoChipOption<double?>(
                          value: distanceMeters,
                          label:
                              '${(distanceMeters / 1000).toStringAsFixed(0)} km',
                        ),
                      ),
                    ],
                    onChanged: onDistanceChanged,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
          _ResultsEntrance(
            // A new query plays the entrance again; filters do not.
            key: ValueKey(trimmedQuery),
            builder: (context, rowEntrance) => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (_, index) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
              itemBuilder: (context, index) => _RowFade(
                animation: rowEntrance(index),
                child: _resultRow(
                  context,
                  index,
                  colorScheme: colorScheme,
                  markerUiMapper: markerUiMapper,
                ),
              ),
            ),
          ),
          if (location == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Text(
                referenceLabel != null
                    ? 'Distancias desde: $referenceLabel'
                    : 'Activa ubicación para ordenar mejor por cercanía.',
                style: OurnegoTextStyles.body.copyWith(fontSize: 12),
              ),
            ),
        ],
      );
    }

    return OurnegoContentContainer(
      backgroundColor: colorScheme.surface,
      borderRadius: OurnegoRadiusTokens.window,
      hasBlur: false,
      customHorizontalPadding: 0,
      customVerticalPadding: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Text(
                  'Buscar',
                  style: OurnegoTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                OurnegoButton.text(
                  size: OurnegoButtonSize.small,
                  label: 'Limpiar',
                  onPressed: onClear,
                ),
                OurnegoIconButton.ghost(
                  size: OurnegoIconButtonSize.s40,
                  icon: Icons.close_rounded,
                  semanticLabel: 'Cerrar búsqueda',
                  tooltip: 'Cerrar búsqueda',
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedSwitcher(
                duration: kFastDuration,
                child: KeyedSubtree(key: ValueKey(bodyState), child: body),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    BuildContext context,
    int index, {
    required ColorScheme colorScheme,
    required BusinessMarkerUiMapper markerUiMapper,
  }) {
    final result = results[index];
    if (result.isCategory) {
      final category = result.category!;
      return ListTile(
        dense: true,
        title: Text(
          businessTypeLabel(category),
          style: OurnegoTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Categoría',
          style: OurnegoTextStyles.body.copyWith(fontSize: 12),
        ),
        leading: Icon(
          markerUiMapper(
            Business(
              id: '',
              name: '',
              description: '',
              ownerId: '',
              address: '',
              phoneNumber: null,
              latitude: 0,
              longitude: 0,
              type: category,
              images: const [],
              visitCount: 0,
              hours: const [],
            ),
          ).icon,
        ),
        trailing: Icon(
          Icons.tune_rounded,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        onTap: () => onCategoryChanged(category),
      );
    }

    final business = result.business!;
    final openLabel = switch (result.openState) {
      BusinessOpenState.open => 'Abierto',
      BusinessOpenState.closed => 'Cerrado',
      BusinessOpenState.unknown => 'Horario no disponible',
    };
    final distanceLabel = result.distanceMeters == null
        ? ''
        : ' · ${(result.distanceMeters! / 1000).toStringAsFixed(1)} km';

    return Builder(
      builder: (rowContext) => ListTile(
        dense: true,
        title: Text(
          business.name,
          style: OurnegoTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${businessTypeLabel(business.type)} · $openLabel$distanceLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: OurnegoTextStyles.body.copyWith(fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        onTap: () => onBusinessSelected(business, globalRectOf(rowContext)),
      ),
    );
  }
}

/// Plays the rows' entrance once, when the results of a query appear. Each row
/// starts 40 ms after the previous one, for the first six rows.
class _ResultsEntrance extends StatefulWidget {
  const _ResultsEntrance({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    Animation<double> Function(int index) rowEntrance,
  )
  builder;

  @override
  State<_ResultsEntrance> createState() => _ResultsEntranceState();
}

class _ResultsEntranceState extends State<_ResultsEntrance>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 360);
  static const int _stepMs = 40;
  static const int _maxStaggeredRows = 6;
  static const int _rowMs = 180;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _rowEntrance(int index) {
    final total = _duration.inMilliseconds;
    final begin = math.min(index, _maxStaggeredRows) * _stepMs / total;
    final end = math.min(1.0, begin + _rowMs / total);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: kEaseOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _rowEntrance);
  }
}

class _RowFade extends StatelessWidget {
  const _RowFade({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
