import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/routing/route_observer.dart';
import 'package:ournego/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

class CompleteProfileScreen extends ConsumerWidget {
  CompleteProfileScreen({super.key});

  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  Future<String?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return pickedFile.path;
    } else {
      return null;
    }
  }

  Future<String?> cropImage() async {
    final path = await pickImage();

    if (path != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: true,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            toolbarTitle: '',
            backgroundColor: Colors.black,
          ),
          IOSUiSettings(aspectRatioLockEnabled: true),
        ],
      );
      if (croppedFile != null) {
        return croppedFile.path;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(authRepositoryProvider);
    final datasource = ref.watch(authScreenTextProvider);
    final errorMessages = ref.watch(authErrorMessagesProvider);
    final text = datasource.completeProfile();
    final asyncUser = ref.watch(profileStreamProvider);
    final imageUrl = asyncUser.value?.profilePicture ?? '';

    return OurnegoPageLayout(
      child: Column(
        children: [
          // Título de la screen
          Text(
            text.title,
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          Spacer(),
          // Campos de texto
          Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1000),
                        child: Image(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                            '$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                          ),
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: OurnegoSemanticTokens.surfaceRaised(
                                Theme.of(context).colorScheme,
                              ),
                              width: double.maxFinite,
                              height: double.maxFinite,
                              child: Icon(
                                Icons.account_circle,
                                size: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final path = await cropImage();

                            if (path != null) {
                              final profilePicture = File(path);
                              UpdateProfileUsecase(
                                repository: repository,
                              ).updateProfilePicture(profilePicture);
                            }
                          },
                          style: ButtonStyle(
                            minimumSize: WidgetStatePropertyAll(Size(50, 50)),
                          ),
                          child: Icon(Icons.edit_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Introducir nombre de usuario
                AutofillGroup(
                  child: Column(
                    children: [
                      // Instrucción
                      Text(
                        text.primaryInstruction,
                        style: OurnegoTextStyles.body,
                      ),
                      SizedBox(height: 10),
                      OurnegoInputField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Crea un nombre de usuario';
                          } else {
                            return null;
                          }
                        },
                        hint: Text(text.primaryHint),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Botón SignUp
                OurnegoPrimaryButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final result = await UpdateProfileUsecase(
                        repository: repository,
                      ).updateUserName(_nameController.text);

                      result.fold(
                        (failure) {
                          final message = errorMessages.getErrorMessage(
                            failure,
                          );
                          // Mostrar error
                          ScaffoldMessenger.of(context).showSnackBar(
                            OurnegoSnackbars.error(context, message),
                          );
                        },
                        (_) async {
                          final setHasSeenOnboarding = ref.read(
                            setHasSeenOnboardingUsecaseProvider,
                          );

                          final firstRouteName = AppRouteObserver
                              .instance
                              .firstRoute
                              ?.settings
                              .name;
                          final isFirstRouteOnboarding =
                              firstRouteName == AppRoutes.onboarding ||
                              firstRouteName == 'onboarding';

                          if (isFirstRouteOnboarding) {
                            await setHasSeenOnboarding();
                            await Future.delayed(Duration(milliseconds: 100));
                            if (!context.mounted) return;
                            context.go(MapRoutes.map);
                            return;
                          }

                          var poppedAnyRoute = false;
                          while (context.canPop()) {
                            poppedAnyRoute = true;
                            context.pop();
                          }

                          if (!poppedAnyRoute) {
                            context.go(MapRoutes.map);
                          }
                        },
                      );
                    }
                  },
                  child: Text(text.primaryButton),
                ),
              ],
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
