// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
//
//  NB: LoginWithGoogleEvent e LoginWithAppleEvent non sono ancora una
//  feature sviluppata/collegata in UI: NON testati qui di proposito
//  (vedi report di fine loop). I relativi usecase sono comunque mockati
//  perche' richiesti dal costruttore del bloc.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/check_session.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_apple.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_email.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_google.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/logout.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/signup_with_email.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckSession extends Mock implements CheckSession {}

class MockLoginWithEmail extends Mock implements LoginWithEmail {}

class MockLoginWithGoogle extends Mock implements LoginWithGoogle {}

class MockLoginWithApple extends Mock implements LoginWithApple {}

class MockSignupWithEmail extends Mock implements SignupWithEmail {}

class MockLogout extends Mock implements Logout {}

void main() {
  late MockCheckSession checkSession;
  late MockLoginWithEmail loginWithEmail;
  late MockLoginWithGoogle loginWithGoogle;
  late MockLoginWithApple loginWithApple;
  late MockSignupWithEmail signupWithEmail;
  late MockLogout logout;

  const tUser = AppAuthUser(id: 'u1', email: 'test@automob.it');
  const tEmail = 'test@automob.it';
  const tPassword = 'password123';
  const tName = 'Mario Rossi';

  setUp(() {
    checkSession = MockCheckSession();
    loginWithEmail = MockLoginWithEmail();
    loginWithGoogle = MockLoginWithGoogle();
    loginWithApple = MockLoginWithApple();
    signupWithEmail = MockSignupWithEmail();
    logout = MockLogout();
  });

  AuthBloc buildBloc() => AuthBloc(
        checkSession: checkSession,
        loginWithEmail: loginWithEmail,
        loginWithGoogle: loginWithGoogle,
        loginWithApple: loginWithApple,
        signupWithEmail: signupWithEmail,
        logout: logout,
      );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, authenticated] quando la sessione e\' attiva',
    build: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(tUser));
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(user: tUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, unauthenticated] quando non c\'e\' sessione',
    build: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [
      AuthLoading(),
      AuthUnauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, unauthenticated] quando il check fallisce',
    build: () {
      when(() => checkSession())
          .thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [
      AuthLoading(),
      AuthUnauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, authenticated] quando il login con email riesce',
    build: () {
      when(() => loginWithEmail(tEmail, tPassword))
          .thenAnswer((_) async => const Right(tUser));
      return buildBloc();
    },
    act: (bloc) =>
        bloc.add(LoginWithEmailEvent(email: tEmail, password: tPassword)),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(user: tUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, error] quando il login con email fallisce',
    build: () {
      when(() => loginWithEmail(tEmail, tPassword)).thenAnswer(
          (_) async => const Left(AuthFailure('Credenziali non valide.')));
      return buildBloc();
    },
    act: (bloc) =>
        bloc.add(LoginWithEmailEvent(email: tEmail, password: tPassword)),
    expect: () => [
      AuthLoading(),
      AuthError(message: 'Credenziali non valide.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, authenticated] quando la registrazione riesce',
    build: () {
      when(() => signupWithEmail(tName, tEmail, tPassword))
          .thenAnswer((_) async => const Right(tUser));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      SignupWithEmailEvent(name: tName, email: tEmail, password: tPassword),
    ),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(user: tUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, error] quando la registrazione fallisce',
    build: () {
      when(() => signupWithEmail(tName, tEmail, tPassword))
          .thenAnswer((_) async => const Left(EmailAlreadyInUseFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      SignupWithEmailEvent(name: tName, email: tEmail, password: tPassword),
    ),
    expect: () => [
      AuthLoading(),
      AuthError(message: const EmailAlreadyInUseFailure().message),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, loggedOut] quando il logout riesce',
    build: () {
      when(() => logout()).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LogoutEvent()),
    expect: () => [
      AuthLoading(),
      AuthLoggedOut(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, error] quando il logout fallisce',
    build: () {
      when(() => logout())
          .thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LogoutEvent()),
    expect: () => [
      AuthLoading(),
      AuthError(message: const ServerFailure().message),
    ],
  );
}
