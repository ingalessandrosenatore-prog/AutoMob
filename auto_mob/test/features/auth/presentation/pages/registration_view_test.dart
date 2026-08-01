import 'dart:async';

import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:auto_mob_v1/features/auth/presentation/pages/registration_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
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

    expect(find.byType(AmTextField), findsNWidgets(3));
    expect(find.text('Registrazione non riuscita'), findsNothing);

    states.add(AuthError(message: 'Questa email e gia registrata.'));
    await tester.pumpAndSettle();

    expect(find.text('Registrazione non riuscita'), findsOneWidget);
    expect(find.text('Questa email e gia registrata.'), findsOneWidget);
    expect(find.text('Chiudi'), findsOneWidget);
  });
}
