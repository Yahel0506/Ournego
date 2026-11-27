import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';

/// Spanish labels of the report reasons, in the order they are offered.
extension BusinessReportReasonLabel on BusinessReportReason {
  String get label => switch (this) {
    BusinessReportReason.noExists => 'No existe / es falso',
    BusinessReportReason.closed => 'Cerró definitivamente',
    BusinessReportReason.incorrectInfo => 'Información incorrecta',
    BusinessReportReason.inappropriate => 'Contenido inapropiado u ofensivo',
    BusinessReportReason.duplicate => 'Duplicado',
    BusinessReportReason.other => 'Otro',
  };
}

/// Dialog to pick a reason and send a report. Use [showBusinessReportDialog].
///
/// It sends the report itself and pops `true` once the server accepted it, so
/// a failure keeps what the user wrote. It never says whether the report will
/// count: that rule lives on the server.
class BusinessReportDialogWidget extends ConsumerStatefulWidget {
  final String businessId;

  const BusinessReportDialogWidget({super.key, required this.businessId});

  @override
  ConsumerState<BusinessReportDialogWidget> createState() =>
      _BusinessReportDialogWidgetState();
}

class _BusinessReportDialogWidgetState
    extends ConsumerState<BusinessReportDialogWidget> {
  static const int _noteMaxLength = 500;

  final TextEditingController _note = TextEditingController();
  BusinessReportReason? _reason;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _messageFor(Failure failure) => switch (failure) {
    BusinessReportLimitFailure() =>
      'Llegaste al límite de reportes de hoy. Inténtalo mañana.',
    BusinessReportUnavailableFailure() =>
      'Este negocio ya no está disponible para reportar.',
    NetworkFailure() =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    _ => 'No se pudo enviar el reporte. Inténtalo de nuevo.',
  };

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) {
      setState(() => _error = 'Elige un motivo.');
      return;
    }
    if (reason.requiresNote && _note.text.trim().isEmpty) {
      setState(() => _error = 'Cuéntanos qué pasa en la nota.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(submitBusinessReportUsecaseProvider)(
      businessId: widget.businessId,
      reason: reason,
      note: _note.text,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = _messageFor(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reason = _reason;
    return OurnegoFormDialog(
      title: 'Reportar negocio',
      isSaving: _saving,
      secondaryAction: OurnegoDialogAction(
        key: const ValueKey('businessReportCancelButton'),
        label: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(false),
      ),
      primaryAction: OurnegoDialogAction(
        key: const ValueKey('businessReportSubmitButton'),
        label: 'Enviar reporte',
        onPressed: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Qué pasa con este negocio?', style: OurnegoTextStyles.body),
          const SizedBox(height: OurnegoSpacingTokens.xs),
          for (final option in BusinessReportReason.values)
            ListTile(
              key: ValueKey('businessReportReason_${option.wire}'),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: OurnegoSpacingTokens.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OurnegoRadiusTokens.lg),
              ),
              selected: option == reason,
              title: Text(option.label),
              trailing: option == reason
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: _saving
                  ? null
                  : () => setState(() {
                      _reason = option;
                      _error = null;
                    }),
            ),
          const SizedBox(height: OurnegoSpacingTokens.sm),
          TextField(
            key: const ValueKey('businessReportNoteField'),
            controller: _note,
            enabled: !_saving,
            maxLength: _noteMaxLength,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: reason != null && reason.requiresNote
                  ? 'Nota (obligatoria)'
                  : 'Nota (opcional)',
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: OurnegoSpacingTokens.xs),
              child: Text(
                _error!,
                key: const ValueKey('businessReportError'),
                style: OurnegoTextStyles.body.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the report dialog and resolves with `true` once the report was sent.
Future<bool> showBusinessReportDialog(
  BuildContext context, {
  required String businessId,
}) async {
  final sent = await showOurnegoDialog<bool>(
    context: context,
    builder: (_) => BusinessReportDialogWidget(businessId: businessId),
  );
  return sent ?? false;
}
