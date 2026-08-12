import '../entities/voice_recognition_update.dart';
import '../repositories/voice_recognition_repository.dart';

class StartVoiceRecognition {
  const StartVoiceRecognition(this._repository);

  final VoiceRecognitionRepository _repository;

  Stream<VoiceRecognitionUpdate> call() => _repository.listen();
}
