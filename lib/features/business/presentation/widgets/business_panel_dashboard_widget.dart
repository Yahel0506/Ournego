import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/pages/components/business_hours_picker.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_editor_dropdown.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_header.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_labels.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_locked_center_card.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_quick_actions.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_states.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/dialogs/location_editor_dialog.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/models/location_editor_result.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

class BusinessPanelDashboardWidget extends ConsumerStatefulWidget {
  const BusinessPanelDashboardWidget({super.key});

  @override
  ConsumerState<BusinessPanelDashboardWidget> createState() =>
      _BusinessPanelDashboardWidgetState();
}

class _BusinessPanelDashboardWidgetState
    extends ConsumerState<BusinessPanelDashboardWidget> {
  bool _isEditorExpanded = false;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _runMutation(Future<void> Function() action) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(ownedBusinessProvider);
      ref.invalidate(isOwnerProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OurnegoSnackbars.info(context, 'Cambios guardados.'));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OurnegoSnackbars.info(
          context,
          'No se pudo guardar. Intenta nuevamente.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editIdentity(
    OwnedBusinessProfile business,
    ContainerTransformOriginController origin,
  ) async {
    final nameController = TextEditingController(text: business.name);
    final descriptionController = TextEditingController(
      text: business.description,
    );
    int category = business.category;

    final didConfirm = await showOurnegoDialog<bool>(
      context: context,
      origin: origin,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return OurnegoFormDialog(
              title: 'Editar informacion',
              primaryAction: OurnegoDialogAction(
                label: 'Guardar',
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              secondaryAction: OurnegoDialogAction(
                label: 'Cancelar',
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OurnegoInputField(
                    controller: nameController,
                    labelText: 'Nombre del negocio',
                  ),
                  const SizedBox(height: OurnegoSpacingTokens.sm),
                  OurnegoInputField(
                    controller: descriptionController,
                    labelText: 'Descripcion',
                    maxLines: 3,
                  ),
                  const SizedBox(height: OurnegoSpacingTokens.sm),
                  DropdownButtonFormField<int>(
                    initialValue: category,
                    items: categoryOptions,
                    onChanged: (value) {
                      setStateDialog(() => category = value ?? category);
                    },
                    decoration: OurnegoInputDecorations.filled(
                      context: dialogContext,
                      labelText: 'Categoria',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (didConfirm != true) return;
    await _runMutation(() async {
      final upsertName = ref.read(upsertBusinessNameUsecaseProvider);
      final upsertDescription = ref.read(
        upsertBusinessDescriptionUsecaseProvider,
      );
      final upsertCategory = ref.read(upsertBusinessCategoryUsecaseProvider);

      final name = nameController.text.trim();
      final description = descriptionController.text.trim();
      if (name.isNotEmpty && name != business.name) {
        final result = await upsertName(businessId: business.id, name: name);
        if (result.isLeft()) throw Exception('upsert name failed');
      }
      if (description != business.description) {
        final result = await upsertDescription(
          businessId: business.id,
          description: description,
        );
        if (result.isLeft()) throw Exception('upsert description failed');
      }
      if (category != business.category) {
        final result = await upsertCategory(
          businessId: business.id,
          category: category,
        );
        if (result.isLeft()) throw Exception('upsert category failed');
      }
    });
  }

  Future<void> _editLocation(OwnedBusinessProfile business) async {
    final result = await showOurnegoDialog<LocationEditorResult>(
      context: context,
      builder: (dialogContext) {
        return LocationEditorDialog(
          initialAddress: business.address,
          initialLatitude: business.latitude,
          initialLongitude: business.longitude,
        );
      },
    );
    if (result == null) return;

    await _runMutation(() async {
      final nextAddress = result.address.trim();
      final changed =
          nextAddress != business.address ||
          result.latitude != business.latitude ||
          result.longitude != business.longitude;
      if (!changed || nextAddress.isEmpty) {
        return;
      }
      final upsertLocation = ref.read(upsertBusinessLocationUsecaseProvider);
      final updateResult = await upsertLocation(
        businessId: business.id,
        address: nextAddress,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (updateResult.isLeft()) throw Exception('upsert location failed');
    });
  }

  Future<void> _editPhone(
    OwnedBusinessProfile business,
    ContainerTransformOriginController origin,
  ) async {
    final controller = TextEditingController(text: business.phoneNumber ?? '');
    final didConfirm = await showOurnegoDialog<bool>(
      context: context,
      origin: origin,
      builder: (dialogContext) {
        return OurnegoFormDialog(
          title: 'Editar telefono',
          primaryAction: OurnegoDialogAction(
            label: 'Guardar',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
          secondaryAction: OurnegoDialogAction(
            label: 'Cancelar',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          child: OurnegoInputField(
            controller: controller,
            keyboardType: TextInputType.phone,
            labelText: 'Telefono',
            hintText: '1234 567 8900',
          ),
        );
      },
    );
    if (didConfirm != true) return;

    await _runMutation(() async {
      final nextPhone = controller.text.trim();
      if (nextPhone == (business.phoneNumber ?? '')) return;
      if (nextPhone.isEmpty) {
        final deleteUsecase = ref.read(
          deleteBusinessPhoneNumberUsecaseProvider,
        );
        final result = await deleteUsecase(businessId: business.id);
        if (result.isLeft()) throw Exception('delete phone failed');
      } else {
        final upsertUsecase = ref.read(
          upsertBusinessPhoneNumberUsecaseProvider,
        );
        final result = await upsertUsecase(
          businessId: business.id,
          phoneNumber: nextPhone,
        );
        if (result.isLeft()) throw Exception('upsert phone failed');
      }
    });
  }

  Future<void> _editHours(
    OwnedBusinessProfile business,
    ContainerTransformOriginController origin,
  ) async {
    final draft = buildScheduleMap(business.hours);
    final didConfirm = await showOurnegoDialog<bool>(
      context: context,
      origin: origin,
      builder: (dialogContext) {
        return OurnegoFormDialog(
          title: 'Editar horarios',
          maxWidth: 420,
          primaryAction: OurnegoDialogAction(
            label: 'Guardar',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
          secondaryAction: OurnegoDialogAction(
            label: 'Cancelar',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          child: Column(
            children: List.generate(7, (day) {
              return Padding(
                padding: const EdgeInsets.only(bottom: OurnegoSpacingTokens.xs),
                child: BusinessHoursPicker(
                  day: day,
                  initialSchedule: draft[day],
                  onChanged: (schedule) {
                    draft[day] = schedule;
                  },
                ),
              );
            }),
          ),
        );
      },
    );
    if (didConfirm != true) return;

    await _runMutation(() async {
      final schedules = draft.values.whereType<AppSchedule>().toList()
        ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
      final upsertHours = ref.read(upsertBusinessHoursUsecaseProvider);
      final result = await upsertHours(
        businessId: business.id,
        hours: schedules,
      );
      if (result.isLeft()) throw Exception('upsert hours failed');
    });
  }

  Future<void> _addGalleryImage(OwnedBusinessProfile business) async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage == null) return;
    final bytes = await pickedImage.readAsBytes();
    if (bytes.isEmpty) return;

    await _runMutation(() async {
      final insertUsecase = ref.read(insertBusinessImageUsecaseProvider);
      final result = await insertUsecase(
        businessId: business.id,
        image: BusinessImageData(
          bytes: bytes,
          fileName: pickedImage.name,
          mimeType: pickedImage.mimeType,
        ),
      );
      if (result.isLeft()) throw Exception('insert image failed');
    });
  }

  Future<void> _deleteGalleryImage({
    required OwnedBusinessProfile business,
    required String imageUrl,
  }) async {
    await _runMutation(() async {
      final deleteUsecase = ref.read(deleteBusinessImageUsecaseProvider);
      final result = await deleteUsecase(
        businessId: business.id,
        imageUrl: imageUrl,
      );
      if (result.isLeft()) throw Exception('delete image failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLogged = ref.watch(authSessionStatusProvider);
    final profileAsync = isLogged ? ref.watch(profileStreamProvider) : null;
    final profileImageUrl = profileAsync?.value?.profilePicture ?? '';
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final ownedBusinessAsync = ref.watch(ownedBusinessProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    OurnegoSpacingTokens.md,
                    OurnegoSpacingTokens.md,
                    OurnegoSpacingTokens.md,
                    90 + bottomSafeArea,
                  ),
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: OurnegoSpacingTokens.xxl),
                      ...ownedBusinessAsync.when(
                        loading: () => const <Widget>[
                          BusinessPanelLoadingState(),
                        ],
                        error: (error, stackTrace) => <Widget>[
                          BusinessPanelErrorState(
                            onRetry: () =>
                                ref.invalidate(ownedBusinessProvider),
                          ),
                        ],
                        data: (ownedBusiness) {
                          if (ownedBusiness == null) {
                            return const <Widget>[BusinessPanelEmptyState()];
                          }

                          return <Widget>[
                            const SizedBox(height: 64),
                            Text(
                              ownedBusiness.name,
                              textAlign: TextAlign.center,
                              style: OurnegoTextStyles.onboardingHeader,
                            ),
                            const SizedBox(height: 64),
                            BusinessPanelEditorDropdown(
                              isExpanded: _isEditorExpanded,
                              onChanged: (expanded) {
                                setState(() {
                                  _isEditorExpanded = expanded;
                                });
                              },
                              ownedBusiness: ownedBusiness,
                              onEditIdentity: (origin) =>
                                  _editIdentity(ownedBusiness, origin),
                              onAddGalleryImage: () =>
                                  _addGalleryImage(ownedBusiness),
                              onDeleteGalleryImage: (imageUrl) =>
                                  _deleteGalleryImage(
                                    business: ownedBusiness,
                                    imageUrl: imageUrl,
                                  ),
                              onEditLocation: () =>
                                  _editLocation(ownedBusiness),
                              onEditPhone: (origin) =>
                                  _editPhone(ownedBusiness, origin),
                              onEditHours: (origin) =>
                                  _editHours(ownedBusiness, origin),
                            ),
                            const SizedBox(height: OurnegoSpacingTokens.md),
                            BusinessPanelLockedCenterCard(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  OurnegoSnackbars.info(
                                    context,
                                    'Mi centro se habilitara en la siguiente fase.',
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: OurnegoSpacingTokens.md),
                            BusinessPanelQuickActions(
                              businessId: ownedBusiness.id,
                              onPlaceholderTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  OurnegoSnackbars.info(
                                    context,
                                    'Esta accion estara disponible pronto.',
                                  ),
                                );
                              },
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSaving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x55000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 30,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BusinessPanelHeader(
                    profileImageUrl: profileImageUrl,
                    isLogged: isLogged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
