import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_anchored_position.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_popover_surface.dart';

/// One entry of [OurnegoChip.dropdown].
@immutable
class OurnegoChipOption<T> {
  const OurnegoChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Lip chip used inside panels (spec §6.9): a filter toggle or a dropdown
/// that opens its options in a popover below itself (`showOurnegoPopover`).
///
/// The class is generic because Dart constructors cannot declare their own
/// type parameters: `OurnegoChip<double?>.dropdown(...)`. The type is
/// inferred from `value` and `options` in most call sites.
class OurnegoChip<T> extends StatelessWidget {
  const OurnegoChip.filter({
    super.key,
    required this.label,
    required bool this.selected,
    required ValueChanged<bool> this.onSelected,
    this.forcePressed = false,
  }) : placeholder = null,
       value = null,
       options = const [],
       onChanged = null;

  const OurnegoChip.dropdown({
    super.key,
    required String this.placeholder,
    required this.value,
    required this.options,
    required ValueChanged<T?> this.onChanged,
    this.forcePressed = false,
  }) : label = null,
       selected = null,
       onSelected = null;

  final String? label;
  final bool? selected;
  final ValueChanged<bool>? onSelected;

  final String? placeholder;
  final T? value;
  final List<OurnegoChipOption<T>> options;
  final ValueChanged<T?>? onChanged;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  bool get _isFilter => selected != null;

  @override
  Widget build(BuildContext context) {
    return _isFilter ? _buildFilter(context) : _buildDropdown(context);
  }

  Widget _chip({
    required BuildContext context,
    required OurnegoButtonTone tone,
    required VoidCallback onPressed,
    required List<Widget> children,
    bool? toggled,
  }) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(const SizedBox(width: OurnegoComponentMetrics.chipGap));
      }
      spaced.add(children[i]);
    }
    return OurnegoPressable(
      onPressed: onPressed,
      colors: ournegoToneColors(context, tone),
      faceHeight: OurnegoComponentMetrics.chipHeight,
      lipDepth: OurnegoComponentMetrics.chipLip,
      borderRadius: BorderRadius.circular(OurnegoComponentMetrics.chipRadius),
      padding: const EdgeInsets.symmetric(
        horizontal: OurnegoComponentMetrics.chipHorizontalPadding,
      ),
      toggled: toggled,
      forcePressed: forcePressed,
      child: Row(mainAxisSize: MainAxisSize.min, children: spaced),
    );
  }

  Widget _text(String text) {
    return Flexible(
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: OurnegoButtonMetrics.small.textStyle,
      ),
    );
  }

  Widget _buildFilter(BuildContext context) {
    final isSelected = selected!;
    return _chip(
      context: context,
      tone: isSelected ? OurnegoButtonTone.primary : OurnegoButtonTone.glass,
      onPressed: () => onSelected!(!isSelected),
      toggled: isSelected,
      children: [
        if (isSelected)
          const Icon(
            Icons.check_rounded,
            size: OurnegoComponentMetrics.chipIconSize,
          ),
        _text(label!),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context) {
    String display = placeholder!;
    if (value != null) {
      for (final option in options) {
        if (option.value == value) {
          display = option.label;
          break;
        }
      }
    }

    return ContainerTransformTrigger(
      radius: OurnegoComponentMetrics.chipRadius,
      color: ournegoToneColors(context, OurnegoButtonTone.glass).face,
      builder: (context, origin) => _chip(
        context: context,
        tone: OurnegoButtonTone.glass,
        onPressed: () => _openOptions(context, origin),
        children: [
          _text(display),
          const Icon(
            Icons.expand_more_rounded,
            size: OurnegoComponentMetrics.chipTrailingIconSize,
          ),
        ],
      ),
    );
  }

  Future<void> _openOptions(
    BuildContext context,
    ContainerTransformOriginController origin,
  ) async {
    final picked = await showOurnegoPopover<_Picked<T>>(
      context: context,
      anchor: origin,
      builder: (popoverContext) => ContainerTransformAnchoredPosition(
        child: Material(
          type: MaterialType.transparency,
          child: OurnegoPopoverSurface(
            // Scrolls when the options do not fit between the chip and the edge
            // of the screen.
            child: SingleChildScrollView(
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < options.length; i++)
                      _OptionTile(
                        key: ValueKey('chipOption_$i'),
                        label: options[i].label,
                        selected: options[i].value == value,
                        onTap: () => Navigator.of(
                          popoverContext,
                        ).pop(_Picked<T>(options[i].value)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (picked != null) onChanged!(picked.value);
  }
}

/// What a popover option pops with. The option's value can be null ("Todas"),
/// so it is wrapped to tell it apart from a dismissed popover.
class _Picked<T> {
  const _Picked(this.value);

  final T value;
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: OurnegoButtonMetrics.small.textStyle.copyWith(
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 18,
              child: selected
                  ? Icon(Icons.check_rounded, size: 18, color: scheme.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
