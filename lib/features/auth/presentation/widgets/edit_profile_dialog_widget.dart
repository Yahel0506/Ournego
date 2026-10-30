import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/domain/profile_name_validator.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';

const String profileUpdatedMessage = 'Perfil actualizado';
const String profilePhotoUpdatedMessage = 'Foto de perfil actualizada';

/// Opens the edit-profile dialog and resolves with the message to confirm what
/// was saved, or `null` when nothing changed.
Future<String?> showEditProfileDialog(
  BuildContext context, {
  ContainerTransformOriginData? from,
  ContainerTransformOriginController? returnTo,
}) {
  return showOurnegoDialog<String>(
    context: context,
    staticOrigin: from,
    returnOrigin: returnTo,
    builder: (_) => const EditProfileDialogWidget(),
  );
}

/// Form to change the display name and the photo of the signed-in user.
///
/// The name is saved with the primary action; the photo is saved as soon as it
/// is chosen. If a save fails the previous value stays and the error is shown
/// inside the dialog.
class EditProfileDialogWidget extends ConsumerStatefulWidget {
  const EditProfileDialogWidget({super.key});

  @override
  ConsumerState<EditProfileDialogWidget> createState() =>
      _EditProfileDialogWidgetState();
}

class _EditProfileDialogWidgetState
    extends ConsumerState<EditProfileDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _nameSeeded = false;
  bool _savingName = false;
  bool _savingPhoto = false;
  bool _photoChanged = false;
  String? _error;

  bool get _busy => _savingName || _savingPhoto;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (_busy) return;
    final photo = await ref.read(profilePhotoPickerProvider).pickSquarePhoto();
    if (photo == null || !mounted) return;

    setState(() {
      _savingPhoto = true;
      _error = null;
    });
    final result = await ref
        .read(updateProfileUsecaseProvider)
        .updateProfilePicture(photo);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _savingPhoto = false;
        _error =
            'No pudimos guardar tu foto. ${ref.read(authErrorMessagesProvider).getErrorMessage(failure)}';
      }),
      (_) {
        ref.read(profileAvatarVersionProvider.notifier).bump();
        setState(() {
          _savingPhoto = false;
          _photoChanged = true;
        });
      },
    );
  }

  Future<void> _saveName() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final current = ref.read(profileStreamProvider).value?.name?.trim();
    if (name == current) {
      Navigator.of(
        context,
      ).pop(_photoChanged ? profilePhotoUpdatedMessage : null);
      return;
    }

    setState(() {
      _savingName = true;
      _error = null;
    });
    final result = await ref
        .read(updateProfileUsecaseProvider)
        .updateUserName(name);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _savingName = false;
        _error =
            'No pudimos guardar tu nombre. ${ref.read(authErrorMessagesProvider).getErrorMessage(failure)}';
      }),
      (_) => Navigator.of(context).pop(profileUpdatedMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileStreamProvider).value;
    if (!_nameSeeded && user != null) {
      _nameSeeded = true;
      _nameController.text = user.name?.trim() ?? '';
    }
    final version = ref.watch(profileAvatarVersionProvider);
    final imageUrl = versionedAvatarUrl(user?.profilePicture ?? '', version);
    final colorScheme = Theme.of(context).colorScheme;

    return OurnegoFormDialog(
      title: 'Editar perfil',
      isSaving: _savingName,
      primaryAction: OurnegoDialogAction(
        key: const ValueKey('editProfileSaveButton'),
        label: 'Guardar',
        onPressed: _saveName,
      ),
      secondaryAction: OurnegoDialogAction(
        key: const ValueKey('editProfileCancelButton'),
        label: 'Cancelar',
        onPressed: () => Navigator.of(
          context,
        ).pop(_photoChanged ? profilePhotoUpdatedMessage : null),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    key: const ValueKey('editProfileAvatar'),
                    radius: 48,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    onForegroundImageError: imageUrl.isNotEmpty
                        ? (_, _) {}
                        : null,
                    child: Icon(
                      Icons.person_rounded,
                      size: 52,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (_savingPhoto)
                    const Positioned.fill(
                      child: Center(
                        key: ValueKey('editProfilePhotoLoading'),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: OurnegoIconButton(
                      key: const ValueKey('editProfilePhotoButton'),
                      tone: OurnegoButtonTone.primary,
                      size: OurnegoIconButtonSize.s44,
                      icon: Icons.edit_rounded,
                      semanticLabel: 'Cambiar foto de perfil',
                      onPressed: _busy ? null : _changePhoto,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OurnegoSpacingTokens.md),
            OurnegoInputField(
              fieldKey: const ValueKey('editProfileNameField'),
              controller: _nameController,
              enabled: !_savingName,
              labelText: 'Nombre',
              hintText: 'Tu nombre',
              validator: ProfileNameValidator.validate,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: OurnegoSpacingTokens.sm),
              Text(
                _error!,
                key: const ValueKey('editProfileError'),
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ] else if (_photoChanged) ...[
              const SizedBox(height: OurnegoSpacingTokens.sm),
              Text(
                profilePhotoUpdatedMessage,
                key: const ValueKey('editProfilePhotoSaved'),
                style: OurnegoTextStyles.bodyCompact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
