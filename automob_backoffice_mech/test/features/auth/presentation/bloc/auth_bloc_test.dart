import 'package:automob_backoffice_mech/features/auth/domain/entities/app_auth_user.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/italian_municipality.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/login_credentials.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/mechanic_registration.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/registration_outcome.dart';
import 'package:automob_backoffice_mech/features/auth/domain/repositories/auth_repository.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/check_auth_session.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/get_italian_municipalities.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/get_pending_verification_email.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/login_with_email.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/register_mechanic.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_event.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

final class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(const LoginCredentials(email: '', password: ''));
    registerFallbackValue(
      const MechanicRegistration(
        fullName: '',
        email: '',
        phone: '',
        password: '',
        businessName: '',
        vatNumber: '',
        streetAddress: '',
        postalCode: '',
        municipalityIstatCode: '',
        municipalityLabel: '',
      ),
    );
  });

  setUp(() {
    repository = _MockAuthRepository();
  });

  test(
    'mostra login quando non esistono sessione o conferma pendente',
    () async {
      when(repository.checkSession).thenAnswer((_) async => const Right(null));
      when(
        repository.getPendingVerificationEmail,
      ).thenAnswer((_) async => const Right(null));
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      final login = _nextState<AuthLogin>(bloc);
      bloc.add(const AuthStarted());

      expect(await login, const AuthLogin());
      verifyNever(repository.getMunicipalities);
    },
  );

  test('login con email e password entra nell app', () async {
    const user = AppAuthUser(id: 'user-1', email: 'meccanico@officina.it');
    when(repository.checkSession).thenAnswer((_) async => const Right(null));
    when(
      repository.getPendingVerificationEmail,
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.loginWithEmail(any()),
    ).thenAnswer((_) async => const Right(user));
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);
    final login = _nextState<AuthLogin>(bloc);
    bloc.add(const AuthStarted());
    await login;

    bloc
      ..add(const LoginEmailChanged('meccanico@officina.it'))
      ..add(const LoginPasswordChanged('ettore1234'));
    await bloc.stream.firstWhere(
      (state) => state is AuthLogin && state.draft.password == 'ettore1234',
    );
    final authenticated = _nextState<AuthAuthenticated>(bloc);
    bloc.add(const LoginSubmitted());

    expect((await authenticated).user, user);
    final captured =
        verify(() => repository.loginWithEmail(captureAny())).captured.single
            as LoginCredentials;
    expect(captured.email, 'meccanico@officina.it');
  });

  test('ripristina la fase di conferma email dopo il riavvio', () async {
    when(repository.checkSession).thenAnswer((_) async => const Right(null));
    when(
      repository.getPendingVerificationEmail,
    ).thenAnswer((_) async => const Right('meccanico@officina.it'));
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);

    final pending = _nextState<AuthEmailVerificationPending>(bloc);
    bloc.add(const AuthStarted());

    expect((await pending).email, 'meccanico@officina.it');
    verifyNever(repository.getMunicipalities);
  });

  test('registra i due step e passa alla conferma email', () async {
    const municipality = ItalianMunicipality(
      code: '058091',
      name: 'Roma',
      provinceCode: 'RM',
      provinceName: 'Roma',
    );
    when(repository.checkSession).thenAnswer((_) async => const Right(null));
    when(
      repository.getPendingVerificationEmail,
    ).thenAnswer((_) async => const Right(null));
    when(
      repository.getMunicipalities,
    ).thenAnswer((_) async => const Right([municipality]));
    when(() => repository.registerMechanic(any())).thenAnswer(
      (_) async =>
          const Right(RegistrationConfirmationRequired('mario@rossi.it')),
    );
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);

    final login = _nextState<AuthLogin>(bloc);
    final registrationReady = _nextState<AuthRegistration>(bloc);
    bloc.add(const AuthStarted());
    await login;
    bloc.add(const RegistrationStarted());
    await registrationReady;

    final personalDraftReady = bloc.stream.firstWhere(
      (state) =>
          state is AuthRegistration &&
          state.draft.passwordConfirmation == 'Password1!',
    );
    bloc
      ..add(const FullNameChanged('Mario Rossi'))
      ..add(const EmailChanged('mario@rossi.it'))
      ..add(const PhoneChanged('+39 333 1234567'))
      ..add(const PasswordChanged('Password1!'))
      ..add(const PasswordConfirmationChanged('Password1!'));
    await personalDraftReady;

    final workshopReady = bloc.stream.firstWhere(
      (state) =>
          state is AuthRegistration && state.step == RegistrationStep.workshop,
    );
    bloc.add(const RegistrationContinuePressed());
    await workshopReady;

    final workshopDraftReady = bloc.stream.firstWhere(
      (state) =>
          state is AuthRegistration && state.draft.municipality == municipality,
    );
    bloc
      ..add(const BusinessNameChanged('Officina Rossi'))
      ..add(const VatNumberChanged('12345678901'))
      ..add(const StreetAddressChanged('Via Roma 10'))
      ..add(const PostalCodeChanged('00100'))
      ..add(const MunicipalityChanged(municipality));
    await workshopDraftReady;

    final confirmation = _nextState<AuthEmailVerificationPending>(bloc);
    bloc.add(const RegistrationContinuePressed());
    expect((await confirmation).email, 'mario@rossi.it');

    final captured =
        verify(() => repository.registerMechanic(captureAny())).captured.single
            as MechanicRegistration;
    expect(captured.businessName, 'Officina Rossi');
    expect(captured.municipalityIstatCode, '058091');
  });

  test('mostra avviso se Ho confermato non trova una sessione', () async {
    when(repository.checkSession).thenAnswer((_) async => const Right(null));
    when(
      repository.getPendingVerificationEmail,
    ).thenAnswer((_) async => const Right('meccanico@officina.it'));
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);
    final pending = _nextState<AuthEmailVerificationPending>(bloc);
    bloc.add(const AuthStarted());
    await pending;

    final warning = bloc.stream.firstWhere(
      (state) =>
          state is AuthEmailVerificationPending &&
          state.dialogMessage?.startsWith('Non hai ancora') == true,
    );
    bloc.add(const EmailConfirmationPressed());

    expect(
      (await warning as AuthEmailVerificationPending).dialogMessage,
      contains('Non hai ancora confermato'),
    );
  });

  test('Ho confermato entra nell app quando la sessione esiste', () async {
    const user = AppAuthUser(id: 'user-1', email: 'meccanico@officina.it');
    var checks = 0;
    when(repository.checkSession).thenAnswer((_) async {
      checks++;
      return checks == 1 ? const Right(null) : const Right(user);
    });
    when(
      repository.getPendingVerificationEmail,
    ).thenAnswer((_) async => const Right('meccanico@officina.it'));
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);
    final pending = _nextState<AuthEmailVerificationPending>(bloc);
    bloc.add(const AuthStarted());
    await pending;

    final authenticated = _nextState<AuthAuthenticated>(bloc);
    bloc.add(const EmailConfirmationPressed());

    expect((await authenticated).user, user);
  });
}

AuthBloc _buildBloc(AuthRepository repository) => AuthBloc(
  loginWithEmail: LoginWithEmail(repository),
  registerMechanic: RegisterMechanic(repository),
  checkAuthSession: CheckAuthSession(repository),
  getPendingVerificationEmail: GetPendingVerificationEmail(repository),
  getItalianMunicipalities: GetItalianMunicipalities(repository),
);

Future<T> _nextState<T extends AuthState>(AuthBloc bloc) =>
    bloc.stream.where((state) => state is T).cast<T>().first;
