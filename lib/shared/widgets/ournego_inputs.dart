import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';

import '../../core/theme/tokens/ournego_radius_tokens.dart';

class OurnegoInputDecorations {
  OurnegoInputDecorations._();

  static InputDecoration filled({
    String? labelText,
    String? hintText,
    TextStyle? hintStyle,
    Widget? icon,
    Widget? hint,
    Widget? suffixIcon,
    BuildContext? context,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: hintStyle,
      icon: icon,
      hint: hint,
      suffixIcon: suffixIcon,
      filled: true,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(OurnegoRadiusTokens.xl)),
      ),
      fillColor: context != null ? Theme.of(context).colorScheme.surface : null,
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
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hint: hint,
        hintStyle: hintStyle,
        icon: icon,
        filled: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(OurnegoRadiusTokens.xl),
          ),
        ),
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
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: OurnegoTextStyles.body),
        SizedBox(height: spacing),
        input,
      ],
    );
  }
}
