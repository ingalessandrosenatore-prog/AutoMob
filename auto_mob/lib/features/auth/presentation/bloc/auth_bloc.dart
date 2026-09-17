import '../../domain/entities/owner_registration.dart';
import '../../domain/usecases/resolve_owner_access.dart';
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

part 'auth_bloc_google.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ResolveOwnerAccess resolveOwnerAccess;
  OwnerRegistration? _googleDraft;
  String? _resolvingUser;
  int _authGeneration = 0;
  bool _loggingOut = false;
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
  late final StreamSubscription<Either<Failure, AppAuthUser?>>
  _sessionSubscription;
  AuthBloc({
    required this.checkSession,
    required this.resolveOwnerAccess,
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
    on<CompleteOwnerProfileEvent>(_onCompleteOwnerProfile);
    on<AuthSessionEndedEvent>((event, emit) {
      _authGeneration++;
      _googleDraft = null;
      emit(AuthUnauthenticated());
    });
    on<AuthStreamFailedEvent>((event, emit) {
      if (!_loggingOut) {
        emit(AuthError(message: 'Accesso interrotto. Riprova.'));
      }
    });
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
    _sessionSubscription = observeAuthenticatedUsers().listen(
      (result) {
        result.fold((_) => add(AuthStreamFailedEvent()), (user) {
          if (_loggingOut) return;
          add(
            user == null
                ? AuthSessionEndedEvent()
                : AuthSessionEstablishedEvent(user: user),
          );
        });
      },
      onError: (Object error, StackTrace stack) => add(AuthStreamFailedEvent()),
    );
  }

  // Check della sessione all'avvio app
  void _onCheckSession(CheckSessionEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await checkSession();
    await result.fold((failure) async => emit(AuthUnauthenticated()), (
      user,
    ) async {
      if (user != null) {
        await _acceptUser(user, emit);
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
    await result.fold<Future<void>>(
      (failure) async => emit(
        AuthError(
          message: failure.message,
          emailNotConfirmed: failure is EmailNotConfirmedFailure,
        ),
      ),
      (user) => _acceptUser(user, emit),
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
    await result.fold<Future<void>>(
      (failure) async => emit(
        current.copyWith(
          status: EmailVerificationStatus.error,
          message: failure.message,
        ),
      ),
      (user) async {
        if (user == null) {
          emit(
            current.copyWith(
              status: EmailVerificationStatus.error,
              message:
                  'La sessione non è arrivata. Apri il link sullo stesso dispositivo o accedi con email e password.',
            ),
          );
        } else {
          await _acceptUser(user, emit);
        }
      },
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

  Future<void> _onAuthSessionEstablished(
    AuthSessionEstablishedEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_loggingOut) return;
    if (state is AuthAuthenticated &&
        (state as AuthAuthenticated).user.id == event.user.id) {
      return;
    }
    if (state is AuthOwnerProfilePending &&
        (state as AuthOwnerProfilePending).user.id == event.user.id) {
      return;
    }
    await _acceptUser(event.user, emit);
  }

  // Login con Apple
  void _onLoginWithApple(
    LoginWithAppleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginWithApple();
    await result.fold<Future<void>>(
      (failure) async => emit(AuthError(message: failure.message)),
      (user) => _acceptUser(user, emit),
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
      event.passwordConfirmation,
      event.phone,
      event.postalCode,
    );
    await result.fold<Future<void>>(
      (failure) async => emit(AuthError(message: failure.message)),
      (outcome) async {
        switch (outcome) {
          case SignupAuthenticated(:final user):
            await _acceptUser(user, emit);
          case SignupConfirmationRequired(:final pendingVerification):
            emit(
              AuthEmailVerificationPending(
                email: pendingVerification.email,
                countdownSeconds: pendingVerification.secondsRemainingAt(now()),
              ),
            );
        }
      },
    );
  }

  // Logout
  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    _authGeneration++;
    _loggingOut = true;
    _googleDraft = null;
    emit(AuthLoading());
    final result = await logout();
    _loggingOut = false;
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
