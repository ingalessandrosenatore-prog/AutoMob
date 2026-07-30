import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class EmailVerificationTimerState {
  const EmailVerificationTimerState(this.secondsRemaining);

  final int secondsRemaining;

  bool get canResend => secondsRemaining <= 60;

  String get formattedTime {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class EmailVerificationTimerCubit extends Cubit<EmailVerificationTimerState> {
  EmailVerificationTimerCubit({this.initialSeconds = 120})
    : super(EmailVerificationTimerState(initialSeconds)) {
    _start();
  }

  final int initialSeconds;
  Timer? _timer;

  void restart([int? seconds]) {
    _timer?.cancel();
    emit(EmailVerificationTimerState(seconds ?? initialSeconds));
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsRemaining == 0) {
        _timer?.cancel();
        return;
      }
      emit(EmailVerificationTimerState(state.secondsRemaining - 1));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
