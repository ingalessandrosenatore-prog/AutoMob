import 'dart:async';

import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:auto_mob_v1/features/auth/presentation/pages/registration_view.dart';
import 'package:auto_mob_v1/features/auth/presentation/pages/login_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets(
    'la transizione espande registrazione e conserva le credenziali',
    (tester) async {
      final authBloc = MockAuthBloc();
      addTearDown(authBloc.close);
      whenListen(
        authBloc,
        const Stream<AuthState>.empty(),
        initialState: AuthUnauthenticated(),
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            theme: ThemeData(extensions: const [AmThemeColors.light]),
            home: const LoginView(),
          ),
        ),
      );

      final loginWidthBefore = tester
          .getSize(find.byKey(const Key('auth-login-action')))
          .width;
      final registrationWidthBefore = tester
          .getSize(find.byKey(const Key('auth-registration-action')))
          .width;
      await tester.enterText(find.byType(TextFormField).first, 'mario@test.it');

      expect(find.byType(PageView), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth-registration-action')));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const Key('auth-login-action'))).width,
        lessThan(loginWidthBefore),
      );
      expect(
        tester.getSize(find.byKey(const Key('auth-registration-action'))).width,
        greaterThan(registrationWidthBefore),
      );
      final enteredValues = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((field) => field.controller?.text)
          .whereType<String>();
      expect(enteredValues, contains('mario@test.it'));
    },
  );

  testWidgets('riusa gli input condivisi e mostra AuthError in un popup', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    addTearDown(authBloc.close);
    whenListen(authBloc, states.stream, initialState: AuthUnauthenticated());

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: ThemeData(extensions: const [AmThemeColors.light]),
          home: const RegistrationView(),
        ),
      ),
    );

    expect(find.text('Benvenuto in'), findsOneWidget);
    expect(find.text('Prenditi cura dei tuoi veicoli'), findsOneWidget);
    expect(find.byKey(const Key('auth-brand-wheel')), findsOneWidget);
    expect(find.byType(AmTextField), findsNWidgets(6));
    expect(
      find.text('CONFERMA PASSWORD *', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('TELEFONO *', findRichText: true), findsOneWidget);
    expect(find.text('CAP *', findRichText: true), findsOneWidget);
    expect(find.text('Registrazione non riuscita'), findsNothing);

    states.add(AuthError(message: 'Questa email e gia registrata.'));
    await tester.pumpAndSettle();

    expect(find.text('Registrazione non riuscita'), findsOneWidget);
    expect(find.text('Questa email e gia registrata.'), findsOneWidget);
    expect(find.text('Chiudi'), findsOneWidget);
  });
}
