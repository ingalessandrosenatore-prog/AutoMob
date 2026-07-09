
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../../domain/usecases/check_session.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/signup_with_email.dart';
import '../../domain/usecases/logout.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckSession checkSession;
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final LoginWithApple loginWithApple;
  final SignupWithEmail signupWithEmail;
  final Logout logout;

  AuthBloc({
    required this.checkSession,
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.loginWithApple,
    required this.signupWithEmail,
    required this.logout,
  }) : super(AuthInitial()) {
    // Evento per controllare la sessione all'avvio (SplashScreen)
    on<CheckSessionEvent>(_onCheckSession);
    
    // Eventi di login
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<LoginWithAppleEvent>(_onLoginWithApple);
    
    // Eventi di registrazione
    on<SignupWithEmailEvent>(_onSignupWithEmail);
    
    // Evento di logout
    on<LogoutEvent>(_onLogout);
    
    // Eventi di navigazione (pura UI, no API)

  }

  // Check della sessione all'avvio app
  void _onCheckSession(CheckSessionEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await checkSession();

    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  // Login con email e password
  void _onLoginWithEmail(LoginWithEmailEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final result = await loginWithEmail(event.email, event.password);

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        emailNotConfirmed: failure is EmailNotConfirmedFailure,
      )),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  // Login con Google
  void _onLoginWithGoogle(LoginWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final result = await loginWithGoogle();
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  // Login con Apple
  void _onLoginWithApple(LoginWithAppleEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final result = await loginWithApple();
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  // Registrazione con email
  void _onSignupWithEmail(SignupWithEmailEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final result = await signupWithEmail(
      event.name,
      event.email,
      event.password,

    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
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


}
