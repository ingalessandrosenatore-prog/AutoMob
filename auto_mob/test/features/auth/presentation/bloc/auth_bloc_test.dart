import 'dart:async';
import 'package:auto_mob_v1/features/auth/domain/usecases/resolve_owner_access.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/owner_registration.dart';
// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
//
// Google regressions also cover deferred OAuth completion below.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/signup_outcome.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/pending_email_verification.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/check_session.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/get_pending_verification_email.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_apple.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_email.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_google.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/logout.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/leave_email_verification.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/observe_authenticated_users.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/signup_with_email.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/resend_confirmation_email.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckSession extends Mock implements CheckSession {}

class MockGetPendingVerificationEmail extends Mock
    implements GetPendingVerificationEmail {}

class MockLoginWithEmail extends Mock implements LoginWithEmail {}

class MockLoginWithGoogle extends Mock implements LoginWithGoogle {}

class MockLoginWithApple extends Mock implements LoginWithApple {}

class MockSignupWithEmail extends Mock implements SignupWithEmail {}

class MockLogout extends Mock implements Logout {}

class MockResendConfirmationEmail extends Mock
    implements ResendConfirmationEmail {}

class MockLeaveEmailVerification extends Mock
    implements LeaveEmailVerification {}

class MockObserveAuthenticatedUsers extends Mock
    implements ObserveAuthenticatedUsers {}

class MockResolveOwnerAccess extends Mock implements ResolveOwnerAccess {}

void main() {
  late MockResolveOwnerAccess resolveOwnerAccess;
  late MockCheckSession checkSession;
  late MockGetPendingVerificationEmail getPendingVerificationEmail;
  late MockLoginWithEmail loginWithEmail;
  late MockLoginWithGoogle loginWithGoogle;
  late MockLoginWithApple loginWithApple;
  late MockSignupWithEmail signupWithEmail;
  late MockLogout logout;
  late MockResendConfirmationEmail resendConfirmationEmail;
  late MockLeaveEmailVerification leaveEmailVerification;
  late MockObserveAuthenticatedUsers observeAuthenticatedUsers;

  const tUser = AppAuthUser(id: 'u1', email: 'test@automob.it');
  const tEmail = 'test@automob.it';
  const tPassword = 'password123';
  const tName = 'Mario Rossi';
  const tPhone = '+39 333 1234567';
  const tPostalCode = '10121';

  setUp(() {
    resolveOwnerAccess = MockResolveOwnerAccess();
    when(() => resolveOwnerAccess()).thenAnswer(
      (_) async => const Right(
        OwnerAccess(needsCompletion: false, profile: OwnerRegistration()),
      ),
    );
    checkSession = MockCheckSession();
    getPendingVerificationEmail = MockGetPendingVerificationEmail();
    loginWithEmail = MockLoginWithEmail();
    loginWithGoogle = MockLoginWithGoogle();
    loginWithApple = MockLoginWithApple();
    signupWithEmail = MockSignupWithEmail();
    logout = MockLogout();
    resendConfirmationEmail = MockResendConfirmationEmail();
    leaveEmailVerification = MockLeaveEmailVerification();
    observeAuthenticatedUsers = MockObserveAuthenticatedUsers();
    when(
      () => observeAuthenticatedUsers(),
    ).thenAnswer((_) => const Stream.empty());
  });

  AuthBloc buildBloc() => AuthBloc(
    checkSession: checkSession,
    resolveOwnerAccess: resolveOwnerAccess,
    getPendingVerificationEmail: getPendingVerificationEmail,
    loginWithEmail: loginWithEmail,
    loginWithGoogle: loginWithGoogle,
    loginWithApple: loginWithApple,
    signupWithEmail: signupWithEmail,
    logout: logout,
    resendConfirmationEmail: resendConfirmationEmail,
    leaveEmailVerification: leaveEmailVerification,
    observeAuthenticatedUsers: observeAuthenticatedUsers,
  );

  test('a late profile response cannot restore access after logout', () async {
    final reply = Completer<Either<Failure, OwnerAccess>>();
    when(() => resolveOwnerAccess()).thenAnswer((_) => reply.future);
    when(() => logout()).thenAnswer((_) async => const Right(null));
    final bloc = buildBloc();
    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(AuthSessionEstablishedEvent(user: tUser));
    await untilCalled(() => resolveOwnerAccess());
    final loggedOut = bloc.stream.firstWhere((state) => state is AuthLoggedOut);
    bloc.add(LogoutEvent());
    await loggedOut;
    reply.complete(
      const Right(
        OwnerAccess(needsCompletion: false, profile: OwnerRegistration()),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(states.whereType<AuthAuthenticated>(), isEmpty);
    expect(bloc.state, isA<AuthLoggedOut>());
    await subscription.cancel();
    await bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'Google launch does not authenticate before callback',
    setUp: () => when(
      () => loginWithGoogle(),
    ).thenAnswer((_) async => const Right(null)),
    build: buildBloc,
    act: (bloc) => bloc.add(LoginWithGoogleEvent()),
    expect: () => [isA<AuthLoading>(), isA<AuthOAuthWaiting>()],
    verify: (_) => verifyNever(() => resolveOwnerAccess()),
  );

  blocTest<AuthBloc, AuthState>(
    'restored Google account with pending profile cannot enter home',
    setUp: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(tUser));
      when(() => resolveOwnerAccess()).thenAnswer(
        (_) async => const Right(
          OwnerAccess(
            needsCompletion: true,
            profile: OwnerRegistration(fullName: 'Mario'),
          ),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [isA<AuthLoading>(), isA<AuthOwnerProfilePending>()],
  );

  blocTest<AuthBloc, AuthState>(
    'Google draft is completed only after the authenticated callback',
    setUp: () {
      when(() => loginWithGoogle()).thenAnswer((_) async => const Right(null));
      when(() => resolveOwnerAccess()).thenAnswer(
        (_) async => const Right(
          OwnerAccess(
            needsCompletion: true,
            profile: OwnerRegistration(fullName: 'Mario'),
          ),
        ),
      );
      when(
        () => resolveOwnerAccess(
          registration: const OwnerRegistration(
            fullName: 'Mario',
            phone: '3331234567',
            postalCode: '00100',
          ),
        ),
      ).thenAnswer(
        (_) async => const Right(
          OwnerAccess(
            needsCompletion: false,
            profile: OwnerRegistration(
              fullName: 'Mario',
              phone: '3331234567',
              postalCode: '00100',
            ),
          ),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(
        LoginWithGoogleEvent(
          registration: const OwnerRegistration(
            phone: '3331234567',
            postalCode: '00100',
          ),
        ),
      );
      await bloc.stream.firstWhere((state) => state is AuthOAuthWaiting);
      bloc.add(AuthSessionEstablishedEvent(user: tUser));
    },
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthOAuthWaiting>(),
      isA<AuthAuthenticated>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'mechanic profile is rejected and signed out',
    setUp: () {
      when(
        () => resolveOwnerAccess(),
      ).thenAnswer((_) async => const Left(PermissionFailure()));
      when(() => logout()).thenAnswer((_) async => const Right(null));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(AuthSessionEstablishedEvent(user: tUser)),
    expect: () => [isA<AuthError>()],
    verify: (_) => verify(() => logout()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, authenticated] quando la sessione e\' attiva',
    build: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(tUser));
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [AuthLoading(), AuthAuthenticated(user: tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, unauthenticated] quando non c\'e\' sessione',
    build: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(null));
      when(
        () => getPendingVerificationEmail(),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [AuthLoading(), AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'riapre l\'attesa quando manca la sessione ma resta una verifica pendente',
    build: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(null));
      when(() => getPendingVerificationEmail()).thenAnswer(
        (_) async => const Right(PendingEmailVerification(email: tEmail)),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [AuthLoading(), AuthEmailVerificationPending(email: tEmail)],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, unauthenticated] quando il check fallisce',
    build: () {
      when(
        () => checkSession(),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(CheckSessionEvent()),
    expect: () => [AuthLoading(), AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, authenticated] quando il login con email riesce',
    build: () {
      when(
        () => loginWithEmail(tEmail, tPassword),
      ).thenAnswer((_) async => const Right(tUser));
      return buildBloc();
    },
    act: (bloc) =>
        bloc.add(LoginWithEmailEvent(email: tEmail, password: tPassword)),
    expect: () => [AuthLoading(), AuthAuthenticated(user: tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, error] quando il login con email fallisce',
    build: () {
      when(() => loginWithEmail(tEmail, tPassword)).thenAnswer(
        (_) async => const Left(AuthFailure('Credenziali non valide.')),
      );
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
    'emette [loading, error] con emailNotConfirmed quando l\'email non e\' '
    'confermata',
    build: () {
      when(
        () => loginWithEmail(tEmail, tPassword),
      ).thenAnswer((_) async => const Left(EmailNotConfirmedFailure()));
      return buildBloc();
    },
    act: (bloc) =>
        bloc.add(LoginWithEmailEvent(email: tEmail, password: tPassword)),
    expect: () => [
      AuthLoading(),
      AuthError(
        message: const EmailNotConfirmedFailure().message,
        emailNotConfirmed: true,
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, authenticated] quando la registrazione riesce',
    build: () {
      when(
        () => signupWithEmail(
          tName,
          tEmail,
          tPassword,
          tPassword,
          tPhone,
          tPostalCode,
        ),
      ).thenAnswer((_) async => const Right(SignupAuthenticated(tUser)));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      SignupWithEmailEvent(
        name: tName,
        email: tEmail,
        password: tPassword,
        passwordConfirmation: tPassword,
        phone: tPhone,
        postalCode: tPostalCode,
      ),
    ),
    expect: () => [AuthLoading(), AuthAuthenticated(user: tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'dopo signup senza sessione emette lo stato di verifica email',
    build: () {
      when(
        () => signupWithEmail(
          tName,
          tEmail,
          tPassword,
          tPassword,
          tPhone,
          tPostalCode,
        ),
      ).thenAnswer(
        (_) async => const Right(
          SignupConfirmationRequired(PendingEmailVerification(email: tEmail)),
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      SignupWithEmailEvent(
        name: tName,
        email: tEmail,
        password: tPassword,
        passwordConfirmation: tPassword,
        phone: tPhone,
        postalCode: tPostalCode,
      ),
    ),
    expect: () => [AuthLoading(), AuthEmailVerificationPending(email: tEmail)],
  );

  blocTest<AuthBloc, AuthState>(
    'il controllo conferma porta ad authenticated quando compare la sessione',
    build: () {
      when(() => checkSession()).thenAnswer((_) async => const Right(tUser));
      return buildBloc();
    },
    seed: () => AuthEmailVerificationPending(email: tEmail),
    act: (bloc) => bloc.add(CheckEmailConfirmationEvent()),
    expect: () => [
      AuthEmailVerificationPending(
        email: tEmail,
        status: EmailVerificationStatus.checking,
      ),
      AuthAuthenticated(user: tUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'reinvia la conferma mantenendo la schermata di attesa',
    build: () {
      when(
        () => resendConfirmationEmail(tEmail),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => AuthEmailVerificationPending(email: tEmail),
    act: (bloc) => bloc.add(ResendConfirmationEmailEvent(email: tEmail)),
    expect: () => [
      AuthEmailVerificationPending(
        email: tEmail,
        status: EmailVerificationStatus.resending,
      ),
      AuthEmailVerificationPending(
        email: tEmail,
        status: EmailVerificationStatus.resent,
        message: 'Email inviata di nuovo.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'la sessione ricevuta dal deep link porta automaticamente alla home',
    build: () {
      when(
        () => observeAuthenticatedUsers(),
      ).thenAnswer((_) => Stream.value(const Right(tUser)));
      return buildBloc();
    },
    expect: () => [AuthAuthenticated(user: tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'consente di uscire dall attesa e tornare al login',
    build: () {
      when(
        () => leaveEmailVerification(),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => AuthEmailVerificationPending(email: tEmail),
    act: (bloc) => bloc.add(LeaveEmailVerificationEvent()),
    expect: () => [AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, error] quando la registrazione fallisce',
    build: () {
      when(
        () => signupWithEmail(
          tName,
          tEmail,
          tPassword,
          tPassword,
          tPhone,
          tPostalCode,
        ),
      ).thenAnswer((_) async => const Left(EmailAlreadyInUseFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      SignupWithEmailEvent(
        name: tName,
        email: tEmail,
        password: tPassword,
        passwordConfirmation: tPassword,
        phone: tPhone,
        postalCode: tPostalCode,
      ),
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
    expect: () => [AuthLoading(), AuthLoggedOut()],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [loading, error] quando il logout fallisce',
    build: () {
      when(() => logout()).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LogoutEvent()),
    expect: () => [
      AuthLoading(),
      AuthError(message: const ServerFailure().message),
    ],
  );
}
