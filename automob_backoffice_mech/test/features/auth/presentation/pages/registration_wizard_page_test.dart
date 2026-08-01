import 'package:automob_backoffice_mech/core/error/failure.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/app_auth_user.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/italian_municipality.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/mechanic_registration.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/registration_outcome.dart';
import 'package:automob_backoffice_mech/features/auth/domain/repositories/auth_repository.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/check_auth_session.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/get_italian_municipalities.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/get_pending_verification_email.dart';
import 'package:automob_backoffice_mech/features/auth/domain/usecases/register_mechanic.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_event.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_state.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/pages/registration_wizard_page.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  testWidgets('la conferma mancante mostra il popup e resta nel wizard', (
    tester,
  ) async {
    final repository = _PendingRepository();
    final bloc = AuthBloc(
      registerMechanic: RegisterMechanic(repository),
      checkAuthSession: CheckAuthSession(repository),
      getPendingVerificationEmail: GetPendingVerificationEmail(repository),
      getItalianMunicipalities: GetItalianMunicipalities(repository),
    );
    addTearDown(bloc.close);
    final pending = bloc.stream
        .where((state) => state is AuthEmailVerificationPending)
        .cast<AuthEmailVerificationPending>()
        .first;
    bloc.add(const AuthStarted());
    await pending;

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AmTheme.light,
          home: const RegistrationWizardPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conferma la tua email'), findsOneWidget);
    expect(find.text('Ho confermato'), findsOneWidget);

    await tester.tap(find.text('Ho confermato'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Email non confermata'), findsOneWidget);
    expect(find.textContaining('Non hai ancora confermato'), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Conferma la tua email'), findsOneWidget);
    expect(bloc.state, isA<AuthEmailVerificationPending>());
  });
}

final class _PendingRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppAuthUser?>> checkSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<ItalianMunicipality>>>
  getMunicipalities() async => const Right([]);

  @override
  Future<Either<Failure, String?>> getPendingVerificationEmail() async =>
      const Right('meccanico@officina.it');

  @override
  Future<Either<Failure, RegistrationOutcome>> registerMechanic(
    MechanicRegistration registration,
  ) => throw UnimplementedError();
}
