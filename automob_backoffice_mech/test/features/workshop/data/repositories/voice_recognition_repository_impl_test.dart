import 'package:automob_backoffice_mech/features/workshop/data/datasources/speech_recognition_data_source.dart';
import 'package:automob_backoffice_mech/features/workshop/data/repositories/voice_recognition_repository_impl.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/voice_recognition_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delega ascolto e stop al datasource', () async {
    final dataSource = _FakeSpeechRecognitionDataSource();
    final repository = VoiceRecognitionRepositoryImpl(dataSource);
    const update = VoiceRecognitionUpdate(
      transcript: 'ab123cd',
      soundLevel: 2,
    );
    dataSource.updates = Stream.value(update);

    expect(await repository.listen().single, update);
    await repository.stop();

    expect(dataSource.stopCalls, 1);
  });
}

final class _FakeSpeechRecognitionDataSource
    implements SpeechRecognitionDataSource {
  Stream<VoiceRecognitionUpdate> updates = const Stream.empty();
  int stopCalls = 0;

  @override
  Stream<VoiceRecognitionUpdate> listen() => updates;

  @override
  Future<void> stop() async => stopCalls++;
}
