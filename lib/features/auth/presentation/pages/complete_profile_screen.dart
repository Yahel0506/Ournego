import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/routing/route_observer.dart';
import 'package:ournego/features/auth/domain/usecases/has_profile_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/animated_background.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          AnimatedBackground(),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 120,
                ),
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
                                        color: Colors.grey.withAlpha(127),
                                        width: double.maxFinite,
                                        height: double.maxFinite,
                                        child: Icon(
                                          Icons.account_circle,
                                          size: 60,
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
                                      minimumSize: WidgetStatePropertyAll(
                                        Size(50, 50),
                                      ),
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
                                TextFormField(
                                  controller: _nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Crea un nombre de usuario';
                                    } else {
                                      return null;
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hint: Text(text.primaryHint),
                                    filled: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),
                          // Botón SignUp
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final result = await UpdateProfileUsecase(
                                  repository: repository,
                                ).updateUserName(_nameController.text);

                                result.fold(
                                  (failure) {
                                    final message = errorMessages
                                        .getErrorMessage(failure);
                                    // Mostrar error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          message,
                                          style: OurnegoTextStyles.errorText,
                                        ),
                                        backgroundColor: Colors.transparent,
                                      ),
                                    );
                                  },
                                  (_) async {
                                    final confirmed = await HasProfileUsecase(
                                      repository: repository,
                                    ).confirmHasProfile();

                                    confirmed.fold(
                                      (failure) {
                                        final message = errorMessages
                                            .getErrorMessage(failure);
                                        // Mostrar error
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              message,
                                              style:
                                                  OurnegoTextStyles.errorText,
                                            ),
                                            backgroundColor: Colors.transparent,
                                          ),
                                        );
                                      },
                                      (_) async {
                                        final prefs =
                                            await SharedPreferences.getInstance();

                                        final firstRouteName = AppRouteObserver
                                            .instance
                                            .firstRoute
                                            ?.settings
                                            .name;
                                        final isFirstRouteOnboarding =
                                            firstRouteName ==
                                                AppRoutes.onboarding ||
                                            firstRouteName == 'onboarding';

                                        if (isFirstRouteOnboarding) {
                                          await prefs.setBool(
                                            'hasSeenOnboarding',
                                            true,
                                          );
                                          await Future.delayed(
                                            Duration(milliseconds: 100),
                                          );
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
                                  },
                                );
                              }
                            },
                            style: ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(
                                Size(double.infinity, 50),
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.pressed)) {
                                  return OurnegoColors.azulVerde;
                                } else {
                                  return OurnegoColors.azulCielo;
                                }
                              }),
                              foregroundColor: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            child: Text(text.primaryButton),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
