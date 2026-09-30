import 'package:automob_backoffice_mech/features/settings/presentation/cubit/theme_mode_cubit.dart';
import 'package:automob_backoffice_mech/features/settings/presentation/pages/settings_page.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra solo lo switch e cambia tra dark e light mode', (
    tester,
  ) async {
    final cubit = ThemeModeCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ThemeModeCubit, bool>(
          builder: (context, isDarkMode) => MaterialApp(
            theme: AmTheme.light,
            darkTheme: AmTheme.dark,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SettingsPage(),
          ),
        ),
      ),
    );

    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.byKey(const ValueKey('dark_mode_switch')), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(cubit.state, isTrue);

    await tester.tap(find.byKey(const ValueKey('dark_mode_switch')));
    await tester.pumpAndSettle();

    expect(cubit.state, isFalse);
    expect(find.text('Light mode'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
  });
}
