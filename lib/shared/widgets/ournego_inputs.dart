import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';

class OurnegoInputDecorations {
  OurnegoInputDecorations._();

  static InputDecoration filled({
    required BuildContext context,
    String? labelText,
    String? hintText,
    TextStyle? hintStyle,
    Widget? icon,
    Widget? hint,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: hintStyle,
      icon: icon,
      hint: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: OurnegoSemanticTokens.surfaceSoft(colorScheme),
    );
  }
}

class OurnegoInputField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? hintText;
  final String? labelText;
  final Widget? hint;
  final TextStyle? hintStyle;
  final Widget? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;

  const OurnegoInputField({
    super.key,
    this.fieldKey,
    this.controller,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.autofillHints,
    this.keyboardType,
    this.maxLines,
    this.hintText,
    this.labelText,
    this.hint,
    this.hintStyle,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      enabled: enabled,
      decoration: OurnegoInputDecorations.filled(
        context: context,
        labelText: labelText,
        hintText: hintText,
        hintStyle: hintStyle,
        icon: icon,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class OurnegoLabeledInputSection extends StatelessWidget {
  final String label;
  final Widget input;
  final double spacing;

  const OurnegoLabeledInputSection({
    super.key,
    required this.label,
    required this.input,
    this.spacing = OurnegoSpacingTokens.inputGap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: OurnegoTextStyles.bodyCompact),
        SizedBox(height: spacing),
        input,
      ],
    );
  }
}
