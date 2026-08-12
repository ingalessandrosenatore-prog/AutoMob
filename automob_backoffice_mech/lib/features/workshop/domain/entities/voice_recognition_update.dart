class VoiceRecognitionUpdate {
  const VoiceRecognitionUpdate({
    required this.transcript,
    required this.soundLevel,
    this.isFinal = false,
  });

  final String transcript;
  final double soundLevel;
  final bool isFinal;
}
