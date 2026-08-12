import '../repositories/voice_recognition_repository.dart';

class StopVoiceRecognition {
  const StopVoiceRecognition(this._repository);

  final VoiceRecognitionRepository _repository;

  Future<void> call() => _repository.stop();
}
