import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/owner_registration.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:auto_mob_v1/features/auth/presentation/pages/google_registration_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('collects phone and CAP before launching Google', (tester) async {
    final bloc = MockAuthBloc();
    addTearDown(bloc.close);
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: AuthUnauthenticated(),
    );
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: ThemeData(extensions: const [AmThemeColors.light]),
          home: const GoogleRegistrationPage(),
        ),
      ),
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Password'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), '3331234567');
    await tester.enterText(find.byType(TextFormField).at(1), '00100');
    await tester.tap(find.text('Continua con Google'));
    verify(
      () => bloc.add(
        LoginWithGoogleEvent(
          registration: const OwnerRegistration(
            phone: '3331234567',
            postalCode: '00100',
          ),
        ),
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored incomplete profile prefills contact fields', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    addTearDown(bloc.close);
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: AuthOwnerProfilePending(
        user: const AppAuthUser(id: 'owner', email: 'owner@example.com'),
        profile: const OwnerRegistration(
          fullName: 'Mario Rossi',
          phone: '3331234567',
          postalCode: '00100',
        ),
      ),
    );
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: ThemeData(extensions: const [AmThemeColors.light]),
          home: const GoogleRegistrationPage(),
        ),
      ),
    );
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Mario Rossi',
    );
    expect(find.text('00100'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Completa registrazione'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
