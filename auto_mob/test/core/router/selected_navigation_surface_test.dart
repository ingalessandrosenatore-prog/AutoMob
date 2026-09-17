import 'package:auto_mob_v1/core/router/shell_scaffold.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la voce selezionata lascia la superficie alla pillola mobile', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: AmNavItem(
            icon: Icons.build_outlined,
            iconIsActive: Icons.build,
            lable: 'Lavori',
            isSelect: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('owner_selected_navigation_border')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owner_selected_navigation_surface')),
      findsNothing,
    );

    expect(find.text('Lavori'), findsOneWidget);
    await tester.tap(find.text('Lavori'));
    expect(taps, 1);
  });
}
