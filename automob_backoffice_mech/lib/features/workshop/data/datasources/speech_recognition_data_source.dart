import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/entities/voice_recognition_update.dart';

abstract interface class SpeechRecognitionDataSource {
  Stream<VoiceRecognitionUpdate> listen();

  Future<void> stop();
}

final class DeviceSpeechRecognitionDataSource
    implements SpeechRecognitionDataSource {
  DeviceSpeechRecognitionDataSource(this._speechToText);

  final SpeechToText _speechToText;
  StreamController<VoiceRecognitionUpdate>? _controller;
  String _transcript = '';
  double _soundLevel = 0;

  @override
  Stream<VoiceRecognitionUpdate> listen() {
    unawaited(stop());
    final controller = StreamController<VoiceRecognitionUpdate>();
    _controller = controller;
    _transcript = '';
    _soundLevel = 0;
    unawaited(_start(controller));
    return controller.stream;
  }

  Future<void> _start(
    StreamController<VoiceRecognitionUpdate> controller,
  ) async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(StateError(error.errorMsg));
          }
        },
        onStatus: (status) {
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            unawaited(_close(controller));
          }
        },
      );
      if (!available) {
        throw StateError('Riconoscimento vocale non disponibile.');
      }
      await _speechToText.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'it_IT',
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.search,
        ),
        onResult: (result) {
          _transcript = result.recognizedWords;
          _emit(controller, isFinal: result.finalResult);
        },
        onSoundLevelChange: (level) {
          _soundLevel = level;
          _emit(controller);
        },
      );
    } on Object catch (error, stackTrace) {
      if (!controller.isClosed) controller.addError(error, stackTrace);
      await _close(controller);
    }
  }

  void _emit(
    StreamController<VoiceRecognitionUpdate> controller, {
    bool isFinal = false,
  }) {
    if (controller.isClosed) return;
    controller.add(
      VoiceRecognitionUpdate(
        transcript: _transcript,
        soundLevel: _soundLevel,
        isFinal: isFinal,
      ),
    );
  }

  @override
  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    if (_speechToText.isListening) await _speechToText.stop();
    if (controller != null) await _close(controller);
  }

  Future<void> _close(
    StreamController<VoiceRecognitionUpdate> controller,
  ) async {
    if (!controller.isClosed) await controller.close();
    if (identical(_controller, controller)) _controller = null;
  }
}
