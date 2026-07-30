import 'package:auto_mob_v1/features/auth/presentation/bloc/email_verification_timer_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('abilita il reinvio al termine del cooldown Supabase', () async {
    final cubit = EmailVerificationTimerCubit(initialSeconds: 61);
    addTearDown(cubit.close);

    expect(cubit.state.canResend, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(cubit.state.secondsRemaining, 60);
    expect(cubit.state.canResend, isTrue);
  });

  test('formatta il timer e riparte dal valore iniziale', () async {
    final cubit = EmailVerificationTimerCubit(initialSeconds: 120);
    addTearDown(cubit.close);

    expect(cubit.state.formattedTime, '2:00');
    cubit.restart();
    expect(cubit.state.secondsRemaining, 120);
  });
}
