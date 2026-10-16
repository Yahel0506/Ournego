import 'package:flutter/material.dart';

import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/presentation/widgets/location_access_sheet_widget.dart';
import 'package:ournego/features/map/presentation/widgets/zone_picker_sheet_widget.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

/// What the location flow ended with: either a plain choice from the access
/// page, or the result of the zone page.
sealed class LocationFlowResult {
  const LocationFlowResult();
}

class LocationFlowAction extends LocationFlowResult {
  const LocationFlowAction(this.action);
  final LocationAccessSheetAction action;
}

class LocationFlowZone extends LocationFlowResult {
  const LocationFlowZone(this.result);
  final ZonePickerResult result;
}

enum LocationFlowPage { access, zone }

/// One sheet for the whole location flow: it opens on the access page and
/// "choose zone" turns it into the zone picker in place, instead of closing it
/// and opening another. Returns null when dismissed.
Future<LocationFlowResult?> showLocationFlowSheet(
  BuildContext context, {
  required LocationAccessStatus status,
  required AppPosition mapCenter,
  ManualZone? currentZone,
  LocationFlowPage initialPage = LocationFlowPage.access,
}) {
  return showOurnegoSheet<LocationFlowResult>(
    context: context,
    builder: (_) => LocationFlowSheet(
      status: status,
      mapCenter: mapCenter,
      currentZone: currentZone,
      initialPage: initialPage,
    ),
  );
}

class LocationFlowSheet extends StatefulWidget {
  const LocationFlowSheet({
    super.key,
    required this.status,
    required this.mapCenter,
    this.currentZone,
    this.initialPage = LocationFlowPage.access,
  });

  final LocationAccessStatus status;
  final AppPosition mapCenter;
  final ManualZone? currentZone;
  final LocationFlowPage initialPage;

  @override
  State<LocationFlowSheet> createState() => _LocationFlowSheetState();
}

class _LocationFlowSheetState extends State<LocationFlowSheet> {
  late LocationFlowPage _page = widget.initialPage;

  void _onAction(LocationAccessSheetAction action) {
    if (action == LocationAccessSheetAction.chooseZone) {
      setState(() => _page = LocationFlowPage.zone);
      return;
    }
    Navigator.of(context).pop(LocationFlowAction(action));
  }

  void _onZoneResult(ZonePickerResult result) {
    Navigator.of(context).pop(LocationFlowZone(result));
  }

  @override
  Widget build(BuildContext context) {
    // The sheet is docked to the bottom, so a change of height grows it
    // upwards, and the two pages cross-fade while it does.
    return AnimatedSize(
      duration: kStandardDuration,
      curve: kEaseOutCubic,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: kFastDuration,
        child: switch (_page) {
          LocationFlowPage.access => LocationAccessSheet(
            key: const ValueKey(LocationFlowPage.access),
            status: widget.status,
            onAction: _onAction,
          ),
          LocationFlowPage.zone => ZonePickerSheet(
            key: const ValueKey(LocationFlowPage.zone),
            mapCenter: widget.mapCenter,
            currentZone: widget.currentZone,
            onResult: _onZoneResult,
          ),
        },
      ),
    );
  }
}
