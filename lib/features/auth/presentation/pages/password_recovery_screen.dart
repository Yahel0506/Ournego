import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final usecase = ref.read(sendPasswordResetEmailUsecaseProvider);
    final errorMessages = ref.read(authErrorMessagesProvider);
    final result = await usecase(_emailController.text.trim());

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
        });
        final message = errorMessages.getErrorMessage(failure);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(OurnegoSnackbars.error(context, message));
      },
      (_) {
        setState(() {
          _isLoading = false;
        });
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OurnegoPageLayout(
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Recupera tu contraseña',
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OurnegoContentContainer(
            child: Form(
              key: _formKey,
              child: OurnegoLabeledInputSection(
                label: 'Introduce tu correo electrónico:',
                input: OurnegoInputField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Introduce tu correo electrónico';
                    }
                    if (!email.isEmail) {
                      return 'El correo no es válido';
                    }
                    return null;
                  },
                  hint: const Text('nombre@dominio.com'),
                ),
              ),
            ),
          ),
          const Spacer(),
          OurnegoButton.primary(
            label: 'Enviar correo',
            expanded: true,
            status: _isLoading
                ? OurnegoButtonStatus.loading
                : OurnegoButtonStatus.idle,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
