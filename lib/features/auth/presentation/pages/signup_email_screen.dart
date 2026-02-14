import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/pages/create_password_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:string_validator/string_validator.dart';

class SignupEmailScreen extends ConsumerStatefulWidget {
  const SignupEmailScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SignupEmailScreenState();
}

class _SignupEmailScreenState extends ConsumerState<SignupEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datasource = ref.watch(authScreenTextProvider);
    final text = datasource.signupEmail();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          AnimatedBackground(),
          Row(
            children: [
              Spacer(),
              ConstrainedBox(
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
                            // Introducir email
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
                                    controller: _emailController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Introduce tu correo electrónico';
                                      }
                                      if (value.isEmail == false) {
                                        return 'Este correo electrónico no es válido. Asegúrate de que tenga un formato como este: ejemplo@email.com';
                                      } else {
                                        return null;
                                      }
                                    },
                                    onChanged: (value) {
                                      _formKey.currentState?.validate();
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
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreatePasswordScreen(
                                            email: _emailController.text,
                                          ),
                                    ),
                                  );
                                }
                              },
                              style: ButtonStyle(
                                minimumSize: WidgetStatePropertyAll(
                                  Size(double.infinity, 50),
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
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
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
