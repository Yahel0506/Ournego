import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:ournego/features/auth/presentation/pages/complete_profile_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          AnimatedBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 120),
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
                            TextFormField(
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
                              decoration: InputDecoration(
                                hint: Text(text.primaryHint),
                                filled: true,
                                border: OutlineInputBorder(),
                              ),
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
                                        ).textTheme.bodyLarge!.color,
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
                                        ).textTheme.bodyLarge!.color,
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
                                style: OurnegoTextStyles.body.copyWith(
                                  color: !minimumLenght
                                      ? Colors.red
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge!.color,
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
                            TextFormField(
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                } else {
                                  return null;
                                }
                              },
                              onChanged: (value) {
                                _formKey.currentState!.validate();
                              },
                              decoration: InputDecoration(
                                hint: Text(text.secondaryHint.toString()),
                                filled: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      // Botón Login
                      ElevatedButton(
                        onPressed: () async {
                          final bool isValid =
                              hasCapitalLetter &&
                              hasNumbersOrSpecialChars &&
                              minimumLenght;
                          if (_formKey.currentState!.validate() && isValid) {
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
                                  SnackBar(
                                    content: Text(
                                      message,
                                      style: OurnegoTextStyles.body.copyWith(
                                        color: Colors.red,
                                      ),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                );
                              },
                              (user) async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setBool('hasSeenOnboarding', true);

                                // Navegar a la siguiente pantalla o mostrar éxito
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CompleteProfileScreen(),
                                  ),
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
        ],
      ),
    );
  }
}
