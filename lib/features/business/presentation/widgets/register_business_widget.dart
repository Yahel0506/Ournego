import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/auth/presentation/widgets/auth_selection_widget.dart';
import 'package:ournego/features/business/domain/usecases/check_if_logged_usecase.dart';
import 'package:ournego/features/business/presentation/pages/business_form_screen.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';

class RegisterBusinessWidget extends ConsumerWidget {
  const RegisterBusinessWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(businessRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Image.asset('assets/images/register_business.png'),
          ),
          const SizedBox(height: 24),
          const Text('Registra tu negocio', style: OurnegoTextStyles.header),
          SizedBox(height: 8),
          const Text(
            'Comienza a crecer creando tu negocio en Ournego, y desbloquea grandes funcionalidades.',
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final isLoggedInResult = await CheckIfLoggedUsecase(repository)();

              isLoggedInResult.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ha habido un error. Por favor, inténtalo de nuevo.',
                        style: OurnegoTextStyles.errorText,
                      ),
                    ),
                  );
                },
                (isLoggedIn) {
                  if (isLoggedIn) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BusinessFormScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AuthSelectionScreen(),
                        settings: RouteSettings(name: '/authSelection'),
                      ),
                    );
                  }
                },
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.secondary,
              ),
              foregroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onSecondary,
              ),
              overlayColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
              fixedSize: WidgetStatePropertyAll(const Size(200, 60)),
            ),
            child: const Text('Comenzar', style: OurnegoTextStyles.header),
          ),
        ],
      ),
    );
  }
}
