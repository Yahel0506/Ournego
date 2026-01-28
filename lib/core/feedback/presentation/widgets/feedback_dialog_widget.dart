import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../providers/feedback_providers.dart';

class FeedbackDialogWidget extends ConsumerWidget {
  const FeedbackDialogWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendFeedbackUsecase = ref.read(sendFeedbackUsecaseProvider);

    return AlertDialog(
      title: Text("¿Algo salió mal? Cuéntanos"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.bug_report, color: Colors.red),
            title: Text("Algo no funciona"),
            onTap: () async {
              Navigator.pop(context);
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final deviceInfo = DeviceInfoPlugin();

                String model = '';
                String osVersion = '';

                if (Platform.isAndroid) {
                  final androidInfo = await deviceInfo.androidInfo;
                  model = androidInfo.model;
                  osVersion = 'Android ${androidInfo.version.release}';
                } else if (Platform.isIOS) {
                  final iosInfo = await deviceInfo.iosInfo;
                  model = iosInfo.utsname.machine;
                  osVersion = 'iOS ${iosInfo.systemVersion}';
                }

                BetterFeedback.of(context).show((feedback) async {
                  final rawImage = feedback.screenshot;
                  final uuid = Uuid();
                  final timestamp = DateTime.now().millisecondsSinceEpoch;

                  // Crear un nombre de archivo simple y válido
                  final fileName =
                      'feedback_${timestamp}_${uuid.v4().replaceAll('-', '')}.png';

                  final tempDir = await getTemporaryDirectory();
                  File image = await File('${tempDir.path}/$fileName').create();
                  image.writeAsBytesSync(rawImage);

                  sendFeedbackUsecase(
                    message: feedback.text,
                    model: model,
                    os: osVersion,
                    attachment: image,
                  );
                });
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.message, color: Colors.blue),
            title: Text("Tengo una duda"),
            onTap: () async {
              await launchUrl(Uri.parse('https://wa.me/3411768237'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
