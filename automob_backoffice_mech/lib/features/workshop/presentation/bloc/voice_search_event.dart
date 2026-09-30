import '../../domain/entities/voice_recognition_update.dart';

sealed class VoiceSearchEvent {
  const VoiceSearchEvent();
}

final class VoiceSearchStarted extends VoiceSearchEvent {
  const VoiceSearchStarted();
}

final class VoiceSearchStopped extends VoiceSearchEvent {
  const VoiceSearchStopped();
}

final class VoiceSearchDismissed extends VoiceSearchEvent {
  const VoiceSearchDismissed();
}

final class VoiceRecognitionUpdated extends VoiceSearchEvent {
  const VoiceRecognitionUpdated(this.update);

  final VoiceRecognitionUpdate update;
}

final class VoiceRecognitionFailed extends VoiceSearchEvent {
  const VoiceRecognitionFailed(this.message);

  final String message;
}

final class VoiceRecognitionCompleted extends VoiceSearchEvent {
  const VoiceRecognitionCompleted();
}
