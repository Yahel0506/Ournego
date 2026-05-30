import 'package:flutter/material.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/controllers/search_businesses_usecase.dart';
import 'package:ournego/features/map/presentation/mappers/business_marker_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class MapSearchOverlayWidget extends StatelessWidget {
  final List<MapSearchResult> results;
  final String query;
  final bool hasData;
  final AppPosition? location;
  final double topBarHeight;
  final double bottomInset;
  final MapSearchFilters filters;
  final List<BusinessType> categoryOptions;
  final List<double> distanceOptionsMeters;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final ValueChanged<bool> onOpenNowChanged;
  final ValueChanged<BusinessType?> onCategoryChanged;
  final ValueChanged<double?> onDistanceChanged;
  final ValueChanged<Business> onBusinessSelected;

  const MapSearchOverlayWidget({
    super.key,
    required this.results,
    required this.query,
    required this.hasData,
    required this.location,
    required this.topBarHeight,
    required this.bottomInset,
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
    if (trimmedQuery.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Escribe para buscar negocios por nombre, categoria o direccion.',
          style: OurnegoTextStyles.body.copyWith(fontSize: 14),
        ),
      );
    } else if (!hasData) {
      body = const Padding(
        padding: EdgeInsets.all(14),
        child: LinearProgressIndicator(minHeight: 2),
      );
    } else if (results.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'No encontramos coincidencias para "$trimmedQuery".',
          style: OurnegoTextStyles.body.copyWith(fontSize: 14),
        ),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                SizedBox(
                  height: 32,
                  child: FilterChip(
                    selected: filters.onlyOpenNow,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      'Abiertos',
                      style: OurnegoTextStyles.body.copyWith(fontSize: 12),
                    ),
                    avatar: Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    onSelected: onOpenNowChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactDropdown<BusinessType?>(
                    value: filters.category,
                    hint: 'Categoría',
                    items: [
                      const DropdownMenuItem<BusinessType?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...categoryOptions.map((type) {
                        return DropdownMenuItem<BusinessType?>(
                          value: type,
                          child: Text(businessTypeLabel(type)),
                        );
                      }),
                    ],
                    onChanged: onCategoryChanged,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactDropdown<double?>(
                    value: filters.maxDistanceMeters,
                    hint: 'Distancia',
                    items: [
                      const DropdownMenuItem<double?>(
                        value: null,
                        child: Text('Sin límite'),
                      ),
                      ...distanceOptionsMeters.map((distanceMeters) {
                        final labelKm = (distanceMeters / 1000).toStringAsFixed(
                          0,
                        );
                        return DropdownMenuItem<double?>(
                          value: distanceMeters,
                          child: Text('$labelKm km'),
                        );
                      }),
                    ],
                    onChanged: onDistanceChanged,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (_, index) => Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.25),
            ),
            itemBuilder: (context, index) {
              final result = results[index];
              if (result.isCategory) {
                final category = result.category!;
                return ListTile(
                  dense: true,
                  title: Text(
                    businessTypeLabel(category),
                    style: OurnegoTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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

              return ListTile(
                dense: true,
                title: Text(
                  business.name,
                  style: OurnegoTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                onTap: () => onBusinessSelected(business),
              );
            },
          ),
          if (location == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Text(
                'Activa ubicación para ordenar mejor por cercanía.',
                style: OurnegoTextStyles.body.copyWith(fontSize: 12),
              ),
            ),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topBarHeight + 10, 16, bottomInset),
        child: OurnegoContentContainer(
          backgroundColor: Theme.of(context).colorScheme.surface,
          borderRadius: 24,
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
                    TextButton(
                      onPressed: onClear,
                      child: const Text('Limpiar'),
                    ),
                    IconButton(
                      tooltip: 'Cerrar búsqueda',
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
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
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _compactDropdown<T>({
  required T value,
  required String hint,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  required ColorScheme colorScheme,
}) {
  return Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      color: colorScheme.surface.withValues(alpha: 0.9),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: Text(
          hint,
          style: OurnegoTextStyles.body.copyWith(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        style: OurnegoTextStyles.body.copyWith(fontSize: 12),
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
        onChanged: onChanged,
        items: items,
      ),
    ),
  );
}
