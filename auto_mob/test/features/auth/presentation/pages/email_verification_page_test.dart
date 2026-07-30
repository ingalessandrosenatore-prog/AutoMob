import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:auto_mob_v1/features/auth/presentation/pages/email_verification_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('mostra email e rispetta il cooldown Supabase', (tester) async {
    final authBloc = MockAuthBloc();
    final pending = AuthEmailVerificationPending(email: 'test@automob.it');
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: pending,
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: ThemeData(extensions: const [AmThemeColors.light]),
          home: const EmailVerificationPage(
            email: 'test@automob.it',
            initialCountdownSeconds: 120,
          ),
        ),
      ),
    );

    expect(find.text('test@automob.it'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.byKey(const Key('resend-counter-badge')), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('resend-email-button')))
          .onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 60));

    expect(find.text('Invia un’altra email'), findsOneWidget);
    expect(find.byKey(const Key('resend-counter-badge')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('resend-email-button')))
          .onPressed,
      isNotNull,
    );
  });
}
