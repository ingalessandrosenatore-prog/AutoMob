import 'package:automob_backoffice_mech/features/workshop/domain/entities/voice_recognition_update.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/repositories/voice_recognition_repository.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/start_voice_recognition.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/stop_voice_recognition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start espone lo stream del repository e stop termina l’ascolto', () async {
    final repository = _FakeVoiceRecognitionRepository();
    final update = const VoiceRecognitionUpdate(
      transcript: 'fiat punto',
      soundLevel: 4,
    );
    repository.updates = Stream.value(update);

    expect(await StartVoiceRecognition(repository)().single, update);
    await StopVoiceRecognition(repository)();

    expect(repository.stopCalls, 1);
  });
}

final class _FakeVoiceRecognitionRepository
    implements VoiceRecognitionRepository {
  Stream<VoiceRecognitionUpdate> updates = const Stream.empty();
  int stopCalls = 0;

  @override
  Stream<VoiceRecognitionUpdate> listen() => updates;

  @override
  Future<void> stop() async => stopCalls++;
}
