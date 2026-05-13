import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/map/presentation/services/voice_search_service.dart';

class MapVoiceSearchState {
  final bool isListening;
  final String transcript;
  final bool isFinal;
  final String? errorMessage;
  final int eventId;

  const MapVoiceSearchState({
    this.isListening = false,
    this.transcript = '',
    this.isFinal = false,
    this.errorMessage,
    this.eventId = 0,
  });

  MapVoiceSearchState copyWith({
    bool? isListening,
    String? transcript,
    bool? isFinal,
    String? errorMessage,
    bool clearError = false,
    int? eventId,
  }) {
    return MapVoiceSearchState(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
      isFinal: isFinal ?? this.isFinal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      eventId: eventId ?? this.eventId,
    );
  }
}

class MapVoiceSearchNotifier extends Notifier<MapVoiceSearchState> {
  final VoiceSearchService voiceSearchService;

  MapVoiceSearchNotifier({required this.voiceSearchService});

  @override
  MapVoiceSearchState build() {
    return const MapVoiceSearchState();
  }

  Future<void> toggleListening() async {
    if (state.isListening) {
      await stopListening();
      return;
    }

    await startListening();
  }

  Future<void> startListening() async {
    state = state.copyWith(
      isListening: true,
      isFinal: false,
      clearError: true,
      eventId: state.eventId + 1,
    );
    await voiceSearchService.startListening(
      onListeningStateChanged: (isListening) {
        state = state.copyWith(
          isListening: isListening,
          eventId: state.eventId + 1,
        );
      },
      onPartialResult: (text) {
        state = state.copyWith(
          isListening: true,
          transcript: text,
          isFinal: false,
          eventId: state.eventId + 1,
        );
      },
      onFinalResult: (text) {
        state = state.copyWith(
          isListening: false,
          transcript: text,
          isFinal: true,
          eventId: state.eventId + 1,
        );
      },
      onError: (message) {
        state = state.copyWith(
          isListening: false,
          errorMessage: message,
          eventId: state.eventId + 1,
        );
      },
    );

    state = state.copyWith(isListening: voiceSearchService.isListening);
  }

  Future<void> stopListening() async {
    await voiceSearchService.stopListening();
    state = state.copyWith(isListening: false, isFinal: true);
  }

  void clearTranscript() {
    state = state.copyWith(transcript: '', isFinal: false);
  }
}
