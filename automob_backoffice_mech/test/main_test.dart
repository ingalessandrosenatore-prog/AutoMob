import 'package:automob_backoffice_mech/main.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_event.dart';
import 'package:automob_backoffice_mech/features/auth/presentation/bloc/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  testWidgets('the mechanic app boots with router and shared theme', (
    tester,
  ) async {
    final authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());

    await tester.pumpWidget(MainApp(authBloc: authBloc));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.routerConfig, isNotNull);
    expect(app.themeMode, ThemeMode.dark);
    expect(
      app.theme?.extension<AmThemeColors>()?.accent,
      const Color(0xFFFF6B00),
    );
  });
}
