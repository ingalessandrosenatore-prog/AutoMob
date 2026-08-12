import '../../domain/entities/voice_recognition_update.dart';
import '../../domain/repositories/voice_recognition_repository.dart';
import '../datasources/speech_recognition_data_source.dart';

final class VoiceRecognitionRepositoryImpl
    implements VoiceRecognitionRepository {
  const VoiceRecognitionRepositoryImpl(this._dataSource);

  final SpeechRecognitionDataSource _dataSource;

  @override
  Stream<VoiceRecognitionUpdate> listen() => _dataSource.listen();

  @override
  Future<void> stop() => _dataSource.stop();
}
