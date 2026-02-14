import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/widgets/auth_selection_widget.dart';
import 'package:ournego/shared/widgets/animated_background.dart';

class AuthSelectionScreen extends ConsumerWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSelection = ref.watch(authSelectionProvider);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(),
          Row(
            children: [
              Spacer(),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: AuthSelectionWidget(
                  title: authSelection.title,
                  imagePath: authSelection.imagePath.toString(),
                  darkImagePath: authSelection.darkImagePath.toString(),
                  googleLogin: authSelection.googleLogin.toString(),
                  emailLogin: authSelection.emailLogin.toString(),
                  phoneLogin: authSelection.phoneLogin.toString(),
                  guestAccess: authSelection.guestAccess.toString(),
                  termsText1: authSelection.termsText1.toString(),
                  termsText2: authSelection.termsText2.toString(),
                  termsText3: authSelection.termsText3.toString(),
                  termsText4: authSelection.termsText4.toString(),
                  onSuccess: () {
                    Navigator.pop(context);
                  },
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
