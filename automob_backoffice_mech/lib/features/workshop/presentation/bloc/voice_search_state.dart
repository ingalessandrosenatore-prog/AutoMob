import 'package:equatable/equatable.dart';

enum VoiceSearchStatus { idle, listening, completed, failure }

final class VoiceSearchState extends Equatable {
  const VoiceSearchState({
    this.status = VoiceSearchStatus.idle,
    this.transcript = '',
    this.amplitude = 0,
    this.message,
  });

  final VoiceSearchStatus status;
  final String transcript;
  final double amplitude;
  final String? message;

  bool get isVisible => status != VoiceSearchStatus.idle;

  bool get isListening => status == VoiceSearchStatus.listening;

  VoiceSearchState copyWith({
    VoiceSearchStatus? status,
    String? transcript,
    double? amplitude,
    String? message,
    bool clearMessage = false,
  }) => VoiceSearchState(
    status: status ?? this.status,
    transcript: transcript ?? this.transcript,
    amplitude: amplitude ?? this.amplitude,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [status, transcript, amplitude, message];
}
