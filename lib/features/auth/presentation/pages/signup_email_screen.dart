import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';

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
                // Introducir email
                AutofillGroup(
                  child: OurnegoLabeledInputSection(
                    label: text.primaryInstruction,
                    input: OurnegoInputField(
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
                      hint: Text(text.primaryHint),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Botón SignUp
                OurnegoPrimaryButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      context.push(
                        AuthRoutes.createPassword,
                        extra: _emailController.text,
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
