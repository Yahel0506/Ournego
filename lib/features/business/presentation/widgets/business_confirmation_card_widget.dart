import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// "¿Conoces este negocio?" card shown inside the business sheet.
///
/// It is a regular sheet element (no popup or modal). It is hidden for guests,
/// for the business owner and, forever, once the server holds an answer from
/// the signed-in user for this business. The card never explains whether an
/// answer counts: that rule lives on the server.
class BusinessConfirmationCardWidget extends ConsumerStatefulWidget {
  final String businessId;
  final String ownerId;

  const BusinessConfirmationCardWidget({
    super.key,
    required this.businessId,
    required this.ownerId,
  });

  @override
  ConsumerState<BusinessConfirmationCardWidget> createState() =>
      _BusinessConfirmationCardWidgetState();
}

class _BusinessConfirmationCardWidgetState
    extends ConsumerState<BusinessConfirmationCardWidget> {
  bool _submitting = false;

  Future<void> _submit(BusinessConfirmationAnswer answer) async {
    setState(() => _submitting = true);
    final failure = await ref
        .read(businessConfirmationProvider(widget.businessId).notifier)
        .submit(answer);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar tu respuesta. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null || userId == widget.ownerId) {
      return const SizedBox.shrink();
    }

    final answer = ref.watch(businessConfirmationProvider(widget.businessId));
    // Show the card only once the server confirmed there is no answer yet, so
    // it never flashes for a user who already answered. A failed read keeps it
    // hidden: the question is optional and must stay discreet.
    final unanswered = answer.hasValue && answer.requireValue == null;
    if (!unanswered) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '¿Conoces este negocio?',
              style: OurnegoTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _AnswerButton(
                  label: 'Sí, lo conozco',
                  icon: Icons.check_rounded,
                  enabled: !_submitting,
                  onPressed: () => _submit(BusinessConfirmationAnswer.yes),
                ),
                _AnswerButton(
                  label: 'No existe / no es real',
                  icon: Icons.close_rounded,
                  enabled: !_submitting,
                  onPressed: () => _submit(BusinessConfirmationAnswer.noExists),
                ),
                _AnswerButton(
                  label: 'No estoy seguro',
                  icon: Icons.help_outline_rounded,
                  enabled: !_submitting,
                  onPressed: () => _submit(BusinessConfirmationAnswer.unsure),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OurnegoButton.secondary(
      size: OurnegoButtonSize.compact,
      label: label,
      icon: icon,
      onPressed: enabled ? onPressed : null,
    );
  }
}
