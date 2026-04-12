import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/widgets/auth_selection_widget.dart';
import 'package:ournego/shared/widgets/animated_background.dart';

class AuthSelectionScreen extends ConsumerWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: const ValueKey('authSelectionScreen'),
      body: Stack(
        children: [
          AnimatedBackground(),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: AuthSelectionWidget(
                onSuccess: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }

                  context.go(MapRoutes.map);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
