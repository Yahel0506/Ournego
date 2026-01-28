import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackDatasource {
  final _supabase = Supabase.instance.client;

  Future<void> sendFeedback({
    required String message,
    required String model,
    required String os,
    required File attachment,
  }) async {
    // Obtener solo el nombre del archivo (sin la ruta completa)
    final fileName = p.basename(attachment.path);

    // Subir el archivo y esperar a que termine
    await _supabase.storage
        .from('feedback_attachments')
        .upload(fileName, attachment);

    // Obtener la URL pública usando el nombre del archivo subido
    final attachmentUrl = _supabase.storage
        .from('feedback_attachments')
        .getPublicUrl(fileName);

    // Insertar en la base de datos con la URL correcta
    await _supabase.from('feedback').insert({
      'message': message,
      'model': model,
      'os': os,
      'attachment': attachmentUrl,
    });
  }
}
