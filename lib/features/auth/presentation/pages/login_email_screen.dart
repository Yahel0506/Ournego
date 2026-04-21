// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/data/datasources/local_auth_screen_text_datasource.dart';
import 'package:ournego/features/auth/data/datasources/local_error_messages_datasource.dart';
import 'package:ournego/features/auth/domain/entities/auth_screen_text.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/domain/usecases/log_in_with_email_usecase.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/onboarding/domain/usecases/get_has_seen_onboarding_usecase.dart';
import 'package:ournego/features/onboarding/domain/usecases/set_has_seen_onboarding_usecase.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

class LoginEmailScreen extends ConsumerStatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LoginEmailScreenState();
}

class _LoginEmailScreenState extends ConsumerState<LoginEmailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalAuthScreenTextDatasource datasource = ref.watch(
      authScreenTextProvider,
    );
    final AuthScreenText text = datasource.loginEmail();
    final repository = ref.watch(authRepositoryProvider);
    final errorMessages = ref.watch(authErrorMessagesProvider);
    final getHasSeenOnboarding = ref.watch(getHasSeenOnboardingUsecaseProvider);
    final setHasSeenOnboarding = ref.watch(setHasSeenOnboardingUsecaseProvider);

    return OurnegoPageLayout(
      scaffoldKey: const ValueKey('loginEmailScreen'),
      child: Column(
        children: [
          // Título de la screen
          Text(text.title, style: OurnegoTextStyles.header),
          Spacer(),
          // Campos de texto
          OurnegoContentContainer(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Introducir email
                  AutofillGroup(
                    child: EmailInput(
                      text: text,
                      controller: _emailController,
                      inputKey: const ValueKey('loginEmailInput'),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Introducir contraseña
                  AutofillGroup(
                    child: PasswordInput(
                      text: text,
                      controller: _passwordController,
                      emailController: _emailController,
                      inputKey: const ValueKey('loginPasswordInput'),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Botón Login
                  PrimaryButton(
                    text: text,
                    repository: repository,
                    errorMessages: errorMessages,
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    getHasSeenOnboarding: getHasSeenOnboarding,
                    setHasSeenOnboarding: setHasSeenOnboarding,
                    buttonKey: const ValueKey('loginSubmitButton'),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          // Texto para hacer SignUp
          InkWell(
            onTap: () {
              context.push(AuthRoutes.signupEmail);
            },
            child: Text(text.signUp.toString(), style: OurnegoTextStyles.link),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.repository,
    required this.errorMessages,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.getHasSeenOnboarding,
    required this.setHasSeenOnboarding,
    required this.buttonKey,
  });

  final AuthScreenText text;
  final AuthRepository repository;
  final LocalErrorMessagesDatasource errorMessages;
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController emailController;
  final GetHasSeenOnboardingUsecase getHasSeenOnboarding;
  final SetHasSeenOnboardingUsecase setHasSeenOnboarding;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    return OurnegoPrimaryButton(
      buttonKey: buttonKey,
      onPressed: () async {
        if (formKey.currentState?.validate() ?? false) {
          final usecase = LogInWithEmailUsecase(repository: repository);

          final result = await usecase(
            email: emailController.text,
            password: passwordController.text,
          );

          result.fold(
            (failure) {
              final message = errorMessages.getErrorMessage(failure);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(OurnegoSnackbars.error(context, message));
              if (failure is UserProfileNotFound) {
                context.push(AuthRoutes.completeProfile);
              } else if (failure is EmailNotVerifiedFailure) {
                context.push(
                  AuthRoutes.verifyEmail,
                  extra: emailController.text,
                );
              }
            },
            (user) async {
              TextInput.finishAutofillContext();
              final hasSeenOnboarding = await getHasSeenOnboarding();

              if (hasSeenOnboarding) {
                // User has seen onboarding, just pop back
                context.pop();
              } else {
                await setHasSeenOnboarding();

                // Pequeña pausa para asegurar que las operaciones anteriores se completen
                await Future.delayed(Duration(milliseconds: 100));

                context.go(MapRoutes.map);
              }
            },
          );
        }
      },
      child: Text(text.primaryButton, style: OurnegoTextStyles.body),
    );
  }
}

class EmailInput extends StatelessWidget {
  const EmailInput({
    super.key,
    required this.text,
    required this.controller,
    required this.inputKey,
  });

  final AuthScreenText text;
  final TextEditingController controller;
  final Key inputKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(text.primaryInstruction, style: OurnegoTextStyles.body),
        SizedBox(height: 10),
        OurnegoInputField(
          fieldKey: inputKey,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          keyboardType: TextInputType.emailAddress,
          controller: controller,
          maxLines: 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Introduce tu correo electrónico';
            }
            // TODO: La validación de email actual impide utilizar emails con caracteres especiales, como la ñ.
            if (value.isEmail == false) {
              return 'El correo no es válido';
            } else {
              return null;
            }
          },
          hint: Text(text.primaryHint),
        ),
      ],
    );
  }
}

class PasswordInput extends StatefulWidget {
  final AuthScreenText text;
  final TextEditingController controller;
  final TextEditingController emailController;
  final Key inputKey;

  const PasswordInput({
    super.key,
    required this.text,
    required this.controller,
    required this.emailController,
    required this.inputKey,
  });

  @override
  State<PasswordInput> createState() =>
      // ignore: no_logic_in_create_state
      _PasswordInputState(controller: controller);
}

class _PasswordInputState extends State<PasswordInput> {
  final TextEditingController controller;

  _PasswordInputState({required this.controller});

  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.text.secondaryInstruction.toString(),
          style: OurnegoTextStyles.body,
        ),
        SizedBox(height: 10),
        OurnegoInputField(
          fieldKey: widget.inputKey,
          autofillHints: const [AutofillHints.password],
          controller: controller,
          maxLines: 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Introduce tu contraseña';
            } else {
              return null;
            }
          },
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _isObscure = !_isObscure;
              });
            },
            icon: _isObscure
                ? Icon(Icons.visibility_off)
                : Icon(Icons.visibility),
          ),
          hint: Text(widget.text.secondaryHint.toString()),
          obscureText: _isObscure,
        ),
        SizedBox(height: 15),
        InkWell(
          onTap: () {
            context.push(
              AuthRoutes.passwordRecovery,
              extra: widget.emailController.text.trim(),
            );
          },
          child: Text(
            widget.text.forgotPassword.toString(),
            style: OurnegoTextStyles.link.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
