import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/debugging/presentation/pages/button_gallery_screen.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  Future<void> resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('hasSeenOnboarding', false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('hasSeenOnboarding = false')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset onboarding'),
              subtitle: const Text('Establece hasSeenOnboarding = false'),
              onTap: () => resetOnboarding(context),
            ),
            ListTile(
              key: const ValueKey('debugButtonGalleryTile'),
              leading: const Icon(Icons.smart_button_rounded),
              title: const Text('Galería de botones'),
              subtitle: const Text('QA visual de la familia de botones'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ButtonGalleryScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
