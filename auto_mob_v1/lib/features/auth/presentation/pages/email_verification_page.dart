import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/am_theme_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/email_verification_timer_cubit.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.initialCountdownSeconds,
  });

  final String email;
  final int initialCountdownSeconds;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EmailVerificationTimerCubit(initialSeconds: initialCountdownSeconds),
      child: _EmailVerificationBody(email: email),
    );
  }
}

class _EmailVerificationBody extends StatelessWidget {
  const _EmailVerificationBody({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthEmailVerificationPending &&
          current.status == EmailVerificationStatus.resent,
      listener: (context, state) {
        final pending = state as AuthEmailVerificationPending;
        context.read<EmailVerificationTimerCubit>().restart(
          pending.countdownSeconds,
        );
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMail01,
                          color: colors.accent,
                          size: 52,
                          strokeWidth: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'CONFERMA LA TUA EMAIL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Per procedere, conferma la tua email all’indirizzo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      key: const Key('verification-email'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    BlocBuilder<
                      EmailVerificationTimerCubit,
                      EmailVerificationTimerState
                    >(
                      builder: (context, timer) {
                        return BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            final pending =
                                authState is AuthEmailVerificationPending
                                ? authState
                                : null;
                            final isResending =
                                pending?.status ==
                                EmailVerificationStatus.resending;
                            final enabled =
                                timer.canResend &&
                                pending != null &&
                                !pending.isBusy;

                            return SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: OutlinedButton(
                                      key: const Key('resend-email-button'),
                                      onPressed: enabled
                                          ? () => context.read<AuthBloc>().add(
                                              ResendConfirmationEmailEvent(
                                                email: email,
                                              ),
                                            )
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: enabled
                                              ? colors.accent
                                              : colors.textSecondary.withValues(
                                                  alpha: 0.35,
                                                ),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            32,
                                          ),
                                        ),
                                      ),
                                      child: isResending
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: colors.accent,
                                              ),
                                            )
                                          : Text(
                                              timer.canResend
                                                  ? 'Invia un’altra email'
                                                  : timer.formattedTime,
                                              style: TextStyle(
                                                color: enabled
                                                    ? colors.accent
                                                    : colors.textSecondary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (timer.canResend &&
                                      timer.secondsRemaining > 0)
                                    Positioned(
                                      right: 22,
                                      top: -11,
                                      child: Container(
                                        key: const Key('resend-counter-badge'),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.background,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: colors.accent,
                                          ),
                                        ),
                                        child: Text(
                                          timer.formattedTime,
                                          style: TextStyle(
                                            color: colors.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final pending = state is AuthEmailVerificationPending
                            ? state
                            : null;
                        final checking =
                            pending?.status == EmailVerificationStatus.checking;
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: FilledButton(
                                key: const Key('check-confirmation-button'),
                                onPressed: pending == null || pending.isBusy
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                        CheckEmailConfirmationEvent(),
                                      ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: checking
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Ho confermato l’email',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            if (pending?.message != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                pending!.message!,
                                key: const Key('verification-message'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      pending.status ==
                                          EmailVerificationStatus.error
                                      ? colors.danger
                                      : colors.info,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('go-to-login-button'),
                      onPressed: () => context.read<AuthBloc>().add(
                        LeaveEmailVerificationEvent(),
                      ),
                      child: Text(
                        'Email gia confermata? Accedi',
                        style: TextStyle(
                          color: colors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
