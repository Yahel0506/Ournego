import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const CreatePasswordScreen({super.key, required this.email});

  @override
  ConsumerState<CreatePasswordScreen> createState() => _CreatePasswordScreen();
}

class _CreatePasswordScreen extends ConsumerState<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;

  bool hasNumbersOrSpecialChars = false;
  bool hasCapitalLetter = false;
  bool minimumLenght = false;

  _CreatePasswordScreen();

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessages = ref.watch(authErrorMessagesProvider);
    final datasource = ref.watch(authScreenTextProvider);
    final signUpWithEmailUsecase = ref.read(signUpWithEmailUsecaseProvider);
    final text = datasource.createPassword();
    final passwordRules = text.passwordRules ?? [];

    return OurnegoPageLayout(
      child: Column(
        children: [
          // Título de la screen
          Text(
            text.title,
            style: OurnegoTextStyles.title,
            textAlign: TextAlign.center,
          ),
          Spacer(),
          // Campos de texto
          OurnegoContentContainer(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Crear contraseña
                  AutofillGroup(
                    child: Column(
                      children: [
                        // Instrucción
                        Text(
                          text.primaryInstruction,
                          style: OurnegoTextStyles.bodyCompact,
                        ),
                        SizedBox(height: 10),
                        OurnegoInputField(
                          controller: _passwordController,
                          onChanged: (value) {
                            setState(() {
                              hasCapitalLetter = value.contains(
                                RegExp(r'[A-Z]'),
                              );
                              hasNumbersOrSpecialChars = value.contains(
                                RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'),
                              );
                              minimumLenght = value.length >= 8;
                            });
                          },
                          hint: Text(text.primaryHint),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasCapitalLetter
                                ? Icons.check
                                : Icons.panorama_fish_eye,
                            size: 12,
                          ),
                          SizedBox(width: 10),
                          Text(
                            passwordRules[0],
                            style: OurnegoTextStyles.bodyCompact.copyWith(
                              color: !hasCapitalLetter
                                  ? OurnegoColorTokens.error
                                  : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            hasNumbersOrSpecialChars
                                ? Icons.check
                                : Icons.panorama_fish_eye,
                            size: 12,
                          ),
                          SizedBox(width: 10),
                          Text(
                            passwordRules[1],
                            style: OurnegoTextStyles.bodyCompact.copyWith(
                              color: !hasNumbersOrSpecialChars
                                  ? OurnegoColorTokens.error
                                  : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            minimumLenght
                                ? Icons.check
                                : Icons.panorama_fish_eye,
                            size: 12,
                          ),
                          SizedBox(width: 10),
                          Text(
                            passwordRules[2],
                            style: OurnegoTextStyles.bodyCompact.copyWith(
                              color: !minimumLenght
                                  ? OurnegoColorTokens.error
                                  : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  AutofillGroup(
                    child: Column(
                      children: [
                        // Instrucción
                        Text(
                          text.secondaryInstruction.toString(),
                          style: OurnegoTextStyles.bodyCompact,
                        ),
                        SizedBox(height: 10),
                        OurnegoInputField(
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            } else {
                              return null;
                            }
                          },
                          onChanged: (value) {
                            _formKey.currentState?.validate();
                          },
                          hint: Text(text.secondaryHint.toString()),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  // Botón Login
                  OurnegoPrimaryButton(
                    onPressed: () async {
                      final bool isValid =
                          hasCapitalLetter &&
                          hasNumbersOrSpecialChars &&
                          minimumLenght;
                      if ((_formKey.currentState?.validate() ?? false) &&
                          isValid) {
                        final result = await signUpWithEmailUsecase(
                          widget.email,
                          _passwordController.text,
                        );

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
                          (user) async {
                            context.push(
                              AuthRoutes.verifyEmail,
                              extra: user.email ?? widget.email,
                            );
                          },
                        );
                      }
                    },
                    child: Text(text.primaryButton),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
