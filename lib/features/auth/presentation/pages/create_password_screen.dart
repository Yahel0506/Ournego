import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const CreatePasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreatePasswordScreen(email: email);
}

class _CreatePasswordScreen extends ConsumerState<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  final String email;

  bool hasNumbersOrSpecialChars = false;
  bool hasCapitalLetter = false;
  bool minimumLenght = false;

  _CreatePasswordScreen({required this.email});

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
    final repository = ref.read(authRepositoryProvider);
    final errorMessages = ref.watch(authErrorMessagesProvider);
    final datasource = ref.watch(authScreenTextProvider);
    final text = datasource.createPassword();
    final passwordRules = text.passwordRules ?? [];

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
                // Crear contraseña
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
                        controller: _passwordController,
                        onChanged: (value) {
                          setState(() {
                            hasCapitalLetter = value.contains(RegExp(r'[A-Z]'));
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
                          style: OurnegoTextStyles.body.copyWith(
                            color: !hasCapitalLetter
                                ? Colors.red
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
                          style: OurnegoTextStyles.body.copyWith(
                            color: !hasNumbersOrSpecialChars
                                ? Colors.red
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
                          minimumLenght ? Icons.check : Icons.panorama_fish_eye,
                          size: 12,
                        ),
                        SizedBox(width: 10),
                        Text(
                          passwordRules[2],
                          style: OurnegoTextStyles.body.copyWith(
                            color: !minimumLenght
                                ? Colors.red
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
                        style: OurnegoTextStyles.body,
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
                      final usecase = SignUpWithEmailUsecase(
                        repository: repository,
                      );

                      final result = await usecase(
                        email,
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
                          // Navegar a la siguiente pantalla o mostrar éxito
                          context.push(AuthRoutes.completeProfile);
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
