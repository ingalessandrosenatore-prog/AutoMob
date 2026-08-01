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
  testWidgets('il wizard mantiene il bottone fermo con la tastiera aperta', (
    tester,
  ) async {
    final repository = _PendingRepository(pendingEmail: null);
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AmTheme.light,
          home: const RegistrationWizardPage(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
    final buttonBefore = tester.getRect(find.byType(AmMainFab));
    // Il quinto campo appartiene allo step anagrafica attualmente visibile;
    // PageView puo' costruire in anticipo anche i campi dello step successivo.
    final focusedField = find.byType(EditableText).at(4);
    await tester.showKeyboard(focusedField);

    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getRect(find.byType(AmMainFab)), buttonBefore);
    final keyboardTop =
        tester.view.physicalSize.height / tester.view.devicePixelRatio -
        tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    expect(tester.getRect(focusedField).bottom, lessThan(keyboardTop));
  });

  testWidgets('trascinare uno step chiude la tastiera', (tester) async {
    final repository = _PendingRepository(pendingEmail: null);
    final bloc = _buildBloc(repository);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AmTheme.light,
          home: const RegistrationWizardPage(),
        ),
      ),
    );

    expect(find.byType(AmEdgeBlur), findsWidgets);
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(
      scrollView.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );

    final editableText = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    await tester.showKeyboard(find.byType(EditableText).first);
    expect(editableText.focusNode.hasFocus, isTrue);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -120),
    );
    await tester.pump();

    expect(editableText.focusNode.hasFocus, isFalse);
  });

  testWidgets('la conferma mancante mostra il popup e resta nel wizard', (
    tester,
  ) async {
    final repository = _PendingRepository();
    final bloc = _buildBloc(repository);
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

AuthBloc _buildBloc(AuthRepository repository) => AuthBloc(
  registerMechanic: RegisterMechanic(repository),
  checkAuthSession: CheckAuthSession(repository),
  getPendingVerificationEmail: GetPendingVerificationEmail(repository),
  getItalianMunicipalities: GetItalianMunicipalities(repository),
);

final class _PendingRepository implements AuthRepository {
  const _PendingRepository({this.pendingEmail = 'meccanico@officina.it'});

  final String? pendingEmail;

  @override
  Future<Either<Failure, AppAuthUser?>> checkSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<ItalianMunicipality>>>
  getMunicipalities() async => const Right([]);

  @override
  Future<Either<Failure, String?>> getPendingVerificationEmail() async =>
      Right(pendingEmail);

  @override
  Future<Either<Failure, RegistrationOutcome>> registerMechanic(
    MechanicRegistration registration,
  ) => throw UnimplementedError();
}
