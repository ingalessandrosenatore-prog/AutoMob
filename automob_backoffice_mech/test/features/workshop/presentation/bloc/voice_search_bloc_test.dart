import 'package:automob_backoffice_mech/features/workshop/domain/entities/voice_recognition_update.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/start_voice_recognition.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/stop_voice_recognition.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_bloc.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_event.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockStartVoiceRecognition extends Mock
    implements StartVoiceRecognition {}

final class _MockStopVoiceRecognition extends Mock
    implements StopVoiceRecognition {}

void main() {
  late _MockStartVoiceRecognition start;
  late _MockStopVoiceRecognition stop;

  setUp(() {
    start = _MockStartVoiceRecognition();
    stop = _MockStopVoiceRecognition();
    when(() => stop()).thenAnswer((_) async {});
  });

  blocTest<VoiceSearchBloc, VoiceSearchState>(
    'mostra risultati parziali e chiude overlay sul risultato finale',
    build: () {
      when(() => start()).thenAnswer(
        (_) => Stream.fromIterable(const [
          VoiceRecognitionUpdate(transcript: 'fiat', soundLevel: 2),
          VoiceRecognitionUpdate(
            transcript: 'fiat punto',
            soundLevel: 8,
            isFinal: true,
          ),
        ]),
      );
      return VoiceSearchBloc(
        startVoiceRecognition: start,
        stopVoiceRecognition: stop,
      );
    },
    act: (bloc) => bloc.add(const VoiceSearchStarted()),
    expect: () => [
      isA<VoiceSearchState>().having(
        (state) => state.status,
        'status',
        VoiceSearchStatus.listening,
      ),
      isA<VoiceSearchState>()
          .having((state) => state.transcript, 'transcript', 'fiat')
          .having((state) => state.amplitude, 'amplitude', greaterThan(0)),
      isA<VoiceSearchState>()
          .having((state) => state.transcript, 'transcript', 'fiat punto')
          .having((state) => state.status, 'status', VoiceSearchStatus.idle),
    ],
  );

  blocTest<VoiceSearchBloc, VoiceSearchState>(
    'stop interrompe il datasource e conserva la trascrizione',
    build: () {
      when(() => start()).thenAnswer((_) => const Stream.empty());
      return VoiceSearchBloc(
        startVoiceRecognition: start,
        stopVoiceRecognition: stop,
      );
    },
    seed: () => const VoiceSearchState(
      status: VoiceSearchStatus.listening,
      transcript: 'alfa romeo',
    ),
    act: (bloc) => bloc.add(const VoiceSearchStopped()),
    expect: () => [
      const VoiceSearchState(
        status: VoiceSearchStatus.idle,
        transcript: 'alfa romeo',
      ),
    ],
    verify: (_) => verify(() => stop()).called(2),
  );
}
