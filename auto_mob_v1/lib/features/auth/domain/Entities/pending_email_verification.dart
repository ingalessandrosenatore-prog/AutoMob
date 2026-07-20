import 'package:equatable/equatable.dart';

class PendingEmailVerification extends Equatable {
  const PendingEmailVerification({required this.email, this.lastSentAt});

  static const countdownDuration = Duration(minutes: 2);

  final String email;
  final DateTime? lastSentAt;

  int secondsRemainingAt(DateTime now) {
    final sentAt = lastSentAt;
    if (sentAt == null) return countdownDuration.inSeconds;
    final remaining = countdownDuration - now.difference(sentAt);
    return remaining.inSeconds.clamp(0, countdownDuration.inSeconds).toInt();
  }

  @override
  List<Object?> get props => [email, lastSentAt];
}
