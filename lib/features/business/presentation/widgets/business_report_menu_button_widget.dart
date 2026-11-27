import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/widgets/business_report_dialog_widget.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';

/// "More" button of the business sheet: opens a small menu whose entry
/// "Reportar negocio" leads to the reasons dialog.
///
/// It is hidden for guests and for the business owner. That is only a
/// convenience: the server rejects a report from the owner anyway.
class BusinessReportMenuButtonWidget extends ConsumerWidget {
  final String businessId;
  final String ownerId;

  const BusinessReportMenuButtonWidget({
    super.key,
    required this.businessId,
    required this.ownerId,
  });

  Future<void> _open(
    BuildContext context,
    ContainerTransformOriginController origin,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final chose = await showOurnegoMenu<bool>(
      context: context,
      origin: origin,
      builder: (_) => const _ReportMenu(),
    );
    if (chose != true || !context.mounted) return;
    final sent = await showBusinessReportDialog(
      context,
      businessId: businessId,
    );
    if (!sent) return;
    // Plain confirmation: nothing about how reports are processed.
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Recibimos tu reporte. Gracias por avisarnos.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null || userId == ownerId) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: OurnegoSpacingTokens.xs),
      child: ContainerTransformTrigger(
        radius: OurnegoRadiusTokens.lg,
        builder: (context, origin) => OurnegoIconButton(
          key: const ValueKey('businessMoreButton'),
          tone: OurnegoButtonTone.tonal,
          outlined: true,
          size: OurnegoIconButtonSize.s32,
          radius: OurnegoRadiusTokens.lg,
          icon: Icons.more_horiz_rounded,
          semanticLabel: 'Más opciones',
          onPressed: () => _open(context, origin),
        ),
      ),
    );
  }
}

class _ReportMenu extends StatelessWidget {
  const _ReportMenu();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OurnegoSpacingTokens.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            type: MaterialType.transparency,
            child: OurnegoDialogSurface(
              customHorizontalPadding: OurnegoSpacingTokens.sm,
              customVerticalPadding: OurnegoSpacingTokens.sm,
              child: ListTile(
                key: const ValueKey('businessReportMenuEntry'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OurnegoRadiusTokens.lg),
                ),
                leading: Icon(Icons.flag_outlined, color: colorScheme.error),
                title: Text(
                  'Reportar negocio',
                  style: OurnegoTextStyles.body.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
