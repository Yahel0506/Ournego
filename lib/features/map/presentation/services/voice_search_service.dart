typedef VoicePartialResultCallback = void Function(String text);
typedef VoiceFinalResultCallback = void Function(String text);
typedef VoiceErrorCallback = void Function(String message);
typedef VoiceListeningStateCallback = void Function(bool isListening);

abstract class VoiceSearchService {
  Future<bool> initialize();

  Future<void> startListening({
    required VoicePartialResultCallback onPartialResult,
    required VoiceFinalResultCallback onFinalResult,
    required VoiceErrorCallback onError,
    required VoiceListeningStateCallback onListeningStateChanged,
  });

  Future<void> stopListening();

  bool get isListening;
}
