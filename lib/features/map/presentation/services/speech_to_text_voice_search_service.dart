import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ournego/features/map/presentation/services/voice_search_service.dart';

class SpeechToTextVoiceSearchService implements VoiceSearchService {
  final SpeechToText _speechToText;

  SpeechToTextVoiceSearchService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  bool _initialized = false;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    _initialized = await _speechToText.initialize();
    return _initialized;
  }

  @override
  Future<void> startListening({
    required VoicePartialResultCallback onPartialResult,
    required VoiceFinalResultCallback onFinalResult,
    required VoiceErrorCallback onError,
    required VoiceListeningStateCallback onListeningStateChanged,
  }) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (micStatus.isPermanentlyDenied) {
        onError(
          'Permiso de micrófono denegado permanentemente. Actívalo en ajustes.',
        );
      } else {
        onError('Activa el micrófono para buscar por voz.');
      }
      onListeningStateChanged(false);
      return;
    }

    final ready = await initialize();
    if (!ready) {
      onError('La búsqueda por voz no está disponible en este dispositivo.');
      onListeningStateChanged(false);
      return;
    }

    final canListen = await _speechToText.initialize(
      onStatus: (status) {
        final normalized = status.toLowerCase();
        final listening = normalized.contains('listening');
        onListeningStateChanged(listening);
      },
      onError: (SpeechRecognitionError error) {
        final text = error.errorMsg.toLowerCase();
        if (text.contains('permission')) {
          onError('Activa el micrófono para buscar por voz.');
          onListeningStateChanged(false);
          return;
        }

        onError('No pudimos completar la búsqueda por voz.');
        onListeningStateChanged(false);
      },
    );
    if (!canListen) {
      onError('La búsqueda por voz no está disponible en este dispositivo.');
      onListeningStateChanged(false);
      return;
    }

    onListeningStateChanged(true);
    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.search,
      ),
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) {
          return;
        }

        if (result.finalResult) {
          onFinalResult(words);
          onListeningStateChanged(false);
        } else {
          onPartialResult(words);
        }
      },
    );
  }

  @override
  Future<void> stopListening() async {
    if (!_speechToText.isListening) {
      return;
    }
    await _speechToText.stop();
  }
}
