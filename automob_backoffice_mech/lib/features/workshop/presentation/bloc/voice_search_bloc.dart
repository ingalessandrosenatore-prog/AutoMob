import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/voice_recognition_update.dart';
import '../../domain/usecases/start_voice_recognition.dart';
import '../../domain/usecases/stop_voice_recognition.dart';
import 'voice_search_event.dart';
import 'voice_search_state.dart';

class VoiceSearchBloc extends Bloc<VoiceSearchEvent, VoiceSearchState> {
  VoiceSearchBloc({
    required this.startVoiceRecognition,
    required this.stopVoiceRecognition,
  }) : super(const VoiceSearchState()) {
    on<VoiceSearchStarted>(_onStarted);
    on<VoiceSearchStopped>(_onStopped);
    on<VoiceSearchDismissed>(_onDismissed);
    on<VoiceRecognitionUpdated>(_onUpdated);
    on<VoiceRecognitionFailed>(_onFailed);
    on<VoiceRecognitionCompleted>(_onCompleted);
  }

  final StartVoiceRecognition startVoiceRecognition;
  final StopVoiceRecognition stopVoiceRecognition;

  StreamSubscription<VoiceRecognitionUpdate>? _subscription;
  double? _minimumLevel;
  double? _maximumLevel;
  double _smoothedAmplitude = 0;

  Future<void> _onStarted(
    VoiceSearchStarted event,
    Emitter<VoiceSearchState> emit,
  ) async {
    if (state.isListening) return;
    await _subscription?.cancel();
    _resetLevels();
    emit(const VoiceSearchState(status: VoiceSearchStatus.listening));
    _subscription = startVoiceRecognition().listen(
      (update) => add(VoiceRecognitionUpdated(update)),
      onError: (Object error, StackTrace stackTrace) =>
          add(VoiceRecognitionFailed(_friendlyMessage(error))),
      onDone: () => add(const VoiceRecognitionCompleted()),
    );
  }

  Future<void> _onStopped(
    VoiceSearchStopped event,
    Emitter<VoiceSearchState> emit,
  ) async {
    await stopVoiceRecognition();
    await _subscription?.cancel();
    _subscription = null;
    emit(
      state.copyWith(
        status: VoiceSearchStatus.idle,
        amplitude: 0,
        clearMessage: true,
      ),
    );
  }

  void _onDismissed(
    VoiceSearchDismissed event,
    Emitter<VoiceSearchState> emit,
  ) {
    emit(const VoiceSearchState());
  }

  void _onUpdated(
    VoiceRecognitionUpdated event,
    Emitter<VoiceSearchState> emit,
  ) {
    final update = event.update;
    emit(
      state.copyWith(
        status: update.isFinal
            ? VoiceSearchStatus.idle
            : VoiceSearchStatus.listening,
        transcript: update.transcript,
        amplitude: _normalizeAndSmooth(update.soundLevel),
        clearMessage: true,
      ),
    );
  }

  void _onFailed(VoiceRecognitionFailed event, Emitter<VoiceSearchState> emit) {
    emit(
      state.copyWith(
        status: VoiceSearchStatus.failure,
        amplitude: 0,
        message: event.message,
      ),
    );
  }

  void _onCompleted(
    VoiceRecognitionCompleted event,
    Emitter<VoiceSearchState> emit,
  ) {
    if (state.status == VoiceSearchStatus.failure ||
        state.status == VoiceSearchStatus.idle ||
        state.status == VoiceSearchStatus.completed) {
      return;
    }
    emit(state.copyWith(status: VoiceSearchStatus.idle, amplitude: 0));
  }

  double _normalizeAndSmooth(double level) {
    _minimumLevel = _minimumLevel == null
        ? level
        : level < _minimumLevel!
        ? level
        : _minimumLevel;
    _maximumLevel = _maximumLevel == null
        ? level
        : level > _maximumLevel!
        ? level
        : _maximumLevel;
    final range = (_maximumLevel! - _minimumLevel!).abs();
    final normalized = range < 0.5
        ? 0.12
        : ((level - _minimumLevel!) / range).clamp(0.0, 1.0);
    _smoothedAmplitude = (_smoothedAmplitude * 0.72) + (normalized * 0.28);
    return _smoothedAmplitude.clamp(0.0, 1.0);
  }

  void _resetLevels() {
    _minimumLevel = null;
    _maximumLevel = null;
    _smoothedAmplitude = 0;
  }

  String _friendlyMessage(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('permission') || value.contains('denied')) {
      return 'Consenti l’accesso al microfono per usare la ricerca vocale.';
    }
    return 'La ricerca vocale non è disponibile. Riprova tra poco.';
  }

  @override
  Future<void> close() async {
    await stopVoiceRecognition();
    await _subscription?.cancel();
    return super.close();
  }
}
