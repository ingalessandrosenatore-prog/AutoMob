import 'package:automob_backoffice_mech/core/error/failure.dart';
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
import 'package:automob_backoffice_mech/features/auth/presentation/pages/login_page.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  testWidgets('mostra campi login e popup di errore accesso', (tester) async {
    final repository = _LoginRepository(
      loginResult: const Left(AuthFailure('Email o password non corretti.')),
    );
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);
    final login = bloc.stream.where((state) => state is AuthLogin).first;
    bloc.add(const AuthStarted());
    await login;

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AmTheme.light,
          home: LoginPage(onRegistrationPressed: () {}),
        ),
      ),
    );

    expect(find.text('AutoMob Officina'), findsOneWidget);
    expect(find.text('Accedi'), findsOneWidget);
    expect(find.text('Crea la tua officina'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'test@officina.it');
    await tester.enterText(find.byType(EditableText).at(1), 'Password1!');
    await tester.tap(find.text('Accedi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Accesso non riuscito'), findsOneWidget);
    expect(find.text('Email o password non corretti.'), findsOneWidget);
  });
}

AuthBloc _buildBloc(AuthRepository repository) => AuthBloc(
  loginWithEmail: LoginWithEmail(repository),
  registerMechanic: RegisterMechanic(repository),
  checkAuthSession: CheckAuthSession(repository),
  getPendingVerificationEmail: GetPendingVerificationEmail(repository),
  getItalianMunicipalities: GetItalianMunicipalities(repository),
);

final class _LoginRepository implements AuthRepository {
  const _LoginRepository({required this.loginResult});

  final Either<Failure, AppAuthUser> loginResult;

  @override
  Future<Either<Failure, AppAuthUser?>> checkSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<ItalianMunicipality>>>
  getMunicipalities() async => const Right([]);

  @override
  Future<Either<Failure, String?>> getPendingVerificationEmail() async =>
      const Right(null);

  @override
  Future<Either<Failure, AppAuthUser>> loginWithEmail(
    LoginCredentials credentials,
  ) async => loginResult;

  @override
  Future<Either<Failure, RegistrationOutcome>> registerMechanic(
    MechanicRegistration registration,
  ) => throw UnimplementedError();
}
