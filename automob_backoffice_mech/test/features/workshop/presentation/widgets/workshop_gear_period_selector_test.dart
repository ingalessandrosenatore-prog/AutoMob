import 'dart:ui' show Tristate;

import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_gear_period_selector.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('espone la selezione e inoltra il nuovo periodo', (tester) async {
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AmThemeColors.dark]),
        home: Scaffold(
          body: WorkshopGearPeriodSelector(
            labels: const ['Giorno', 'Mensile', 'Annuale'],
            selectedIndex: selectedIndex,
            onChanged: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('GIORNO')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.tap(find.text('MENSILE'));
    expect(selectedIndex, 1);
  });

  testWidgets('richiede tre marce e un indice valido', (tester) async {
    expect(
      () => WorkshopGearPeriodSelector(
        labels: const ['Giorno', 'Mensile'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
    expect(
      () => WorkshopGearPeriodSelector(
        labels: const ['Giorno', 'Mensile', 'Annuale'],
        selectedIndex: 3,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('renderizza il percorso anche con la palette chiara', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AmThemeColors.light]),
        home: Scaffold(
          body: WorkshopGearPeriodSelector(
            labels: const ['Giorno', 'Mensile', 'Annuale'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('am_gear_gate')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
