import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/check_session.dart';
import '../../domain/entities/signup_outcome.dart';
import '../../domain/usecases/get_pending_verification_email.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/signup_with_email.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/leave_email_verification.dart';
import '../../domain/usecases/observe_authenticated_users.dart';
import '../../domain/usecases/resend_confirmation_email.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckSession checkSession;
  final GetPendingVerificationEmail getPendingVerificationEmail;
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final LoginWithApple loginWithApple;
  final SignupWithEmail signupWithEmail;
  final Logout logout;
  final ResendConfirmationEmail resendConfirmationEmail;
  final LeaveEmailVerification leaveEmailVerification;
  final ObserveAuthenticatedUsers observeAuthenticatedUsers;
  final DateTime Function() now;
  late final StreamSubscription<Either<Failure, AppAuthUser>>
  _sessionSubscription;

  AuthBloc({
    required this.checkSession,
    required this.getPendingVerificationEmail,
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.loginWithApple,
    required this.signupWithEmail,
    required this.logout,
    required this.resendConfirmationEmail,
    required this.leaveEmailVerification,
    required this.observeAuthenticatedUsers,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now,
       super(AuthInitial()) {
    // Evento per controllare la sessione all'avvio (SplashScreen)
    on<CheckSessionEvent>(_onCheckSession);

    // Eventi di login
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<LoginWithAppleEvent>(_onLoginWithApple);

    // Eventi di registrazione
    on<SignupWithEmailEvent>(_onSignupWithEmail);
    on<ResendConfirmationEmailEvent>(_onResendConfirmationEmail);
    on<CheckEmailConfirmationEvent>(_onCheckEmailConfirmation);
    on<LeaveEmailVerificationEvent>(_onLeaveEmailVerification);
    on<AuthSessionEstablishedEvent>(_onAuthSessionEstablished);

    // Evento di logout
    on<LogoutEvent>(_onLogout);

    // Eventi di navigazione (pura UI, no API)
    _sessionSubscription = observeAuthenticatedUsers().listen((result) {
      result.fold(
        (_) {},
        (user) => add(AuthSessionEstablishedEvent(user: user)),
      );
    });
  }

  // Check della sessione all'avvio app
  void _onCheckSession(CheckSessionEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await checkSession();

    await result.fold((failure) async => emit(AuthUnauthenticated()), (
      user,
    ) async {
      if (user != null) {
        emit(AuthAuthenticated(user: user));
        return;
      }

      final pendingResult = await getPendingVerificationEmail();
      pendingResult.fold(
        (_) => emit(AuthUnauthenticated()),
        (pending) => emit(
          pending == null
              ? AuthUnauthenticated()
              : AuthEmailVerificationPending(
                  email: pending.email,
                  countdownSeconds: pending.secondsRemainingAt(now()),
                ),
        ),
      );
    });
  }

  // Login con email e password
  void _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginWithEmail(event.email, event.password);

    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          emailNotConfirmed: failure is EmailNotConfirmedFailure,
        ),
      ),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onResendConfirmationEmail(
    ResendConfirmationEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailVerificationPending || current.isBusy) return;

    emit(
      current.copyWith(
        status: EmailVerificationStatus.resending,
        clearMessage: true,
      ),
    );
    final result = await resendConfirmationEmail(event.email);
    result.fold(
      (failure) => emit(
        current.copyWith(
          status: EmailVerificationStatus.error,
          message: failure.message,
        ),
      ),
      (_) => emit(
        current.copyWith(
          countdownSeconds: 120,
          status: EmailVerificationStatus.resent,
          message: 'Email inviata di nuovo.',
        ),
      ),
    );
  }

  Future<void> _onCheckEmailConfirmation(
    CheckEmailConfirmationEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailVerificationPending || current.isBusy) return;

    emit(
      current.copyWith(
        status: EmailVerificationStatus.checking,
        clearMessage: true,
      ),
    );
    final result = await checkSession();
    result.fold(
      (failure) => emit(
        current.copyWith(
          status: EmailVerificationStatus.error,
          message: failure.message,
        ),
      ),
      (user) => emit(
        user == null
            ? current.copyWith(
                status: EmailVerificationStatus.error,
                message:
                    'La sessione non e arrivata all app. Apri il link '
                    'ricevuto sullo stesso dispositivo oppure accedi con '
                    'email e password.',
              )
            : AuthAuthenticated(user: user),
      ),
    );
  }

  Future<void> _onLeaveEmailVerification(
    LeaveEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailVerificationPending || current.isBusy) return;
    final result = await leaveEmailVerification();
    result.fold(
      (failure) => emit(
        current.copyWith(
          status: EmailVerificationStatus.error,
          message: failure.message,
        ),
      ),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  void _onAuthSessionEstablished(
    AuthSessionEstablishedEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(user: event.user));
  }

  // Login con Google
  void _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginWithGoogle();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  // Login con Apple
  void _onLoginWithApple(
    LoginWithAppleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginWithApple();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  // Registrazione con email
  void _onSignupWithEmail(
    SignupWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await signupWithEmail(
      event.name,
      event.email,
      event.password,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (outcome) => switch (outcome) {
        SignupAuthenticated(:final user) => emit(AuthAuthenticated(user: user)),
        SignupConfirmationRequired(:final pendingVerification) => emit(
          AuthEmailVerificationPending(
            email: pendingVerification.email,
            countdownSeconds: pendingVerification.secondsRemainingAt(now()),
          ),
        ),
      },
    );
  }

  // Logout
  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await logout();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthLoggedOut()),
    );
  }

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    return super.close();
  }
}
