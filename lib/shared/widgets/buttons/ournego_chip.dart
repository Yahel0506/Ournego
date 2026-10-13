import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// One entry of [OurnegoChip.dropdown].
@immutable
class OurnegoChipOption<T> {
  const OurnegoChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Lip chip used inside panels (spec §6.9): a filter toggle or a dropdown
/// that opens a [MenuAnchor] below itself.
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

    return MenuAnchor(
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            onPressed: () => onChanged!(option.value),
            child: Text(option.label),
          ),
      ],
      builder: (context, controller, _) {
        return _chip(
          context: context,
          tone: OurnegoButtonTone.glass,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          children: [
            _text(display),
            const Icon(
              Icons.expand_more_rounded,
              size: OurnegoComponentMetrics.chipTrailingIconSize,
            ),
          ],
        );
      },
    );
  }
}
