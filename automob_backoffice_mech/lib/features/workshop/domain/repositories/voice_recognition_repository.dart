import '../entities/voice_recognition_update.dart';

abstract interface class VoiceRecognitionRepository {
  Stream<VoiceRecognitionUpdate> listen();

  Future<void> stop();
}
