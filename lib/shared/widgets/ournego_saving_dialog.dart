import 'package:flutter/material.dart';

/// Keeps a form dialog open while its save runs.
///
/// The [builder] draws the dialog (an `OurnegoFormDialog`) with [isSaving] and
/// [error], and calls `submit(value)` from its primary action. While saving,
/// back and a tap outside do nothing. When [save] finishes the dialog closes
/// with `true`; when it throws, the dialog stays with what the user typed and
/// shows [errorText].
class OurnegoSavingDialog<T> extends StatefulWidget {
  const OurnegoSavingDialog({
    super.key,
    required this.save,
    required this.builder,
    this.errorText = 'No se pudo guardar. Intenta nuevamente.',
  });

  final Future<void> Function(T value) save;
  final Widget Function(
    BuildContext context,
    bool isSaving,
    String? error,
    Future<void> Function(T value) submit,
  )
  builder;
  final String errorText;

  @override
  State<OurnegoSavingDialog<T>> createState() => _OurnegoSavingDialogState<T>();
}

class _OurnegoSavingDialogState<T> extends State<OurnegoSavingDialog<T>> {
  bool _isSaving = false;
  String? _error;

  Future<void> _submit(T value) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.save(value);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = widget.errorText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: widget.builder(context, _isSaving, _error, _submit),
    );
  }
}
