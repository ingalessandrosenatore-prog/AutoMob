import 'dart:ui' show Tristate;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('espone la marcia selezionata e inoltra il nuovo periodo', (
    tester,
  ) async {
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: AmGearPeriodSelector(
            labels: const ['Giornaliero', 'Mensile', 'Annuale'],
            selectedIndex: selectedIndex,
            onChanged: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('GIORNALIERO')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.tap(find.text('MENSILE'));
    expect(selectedIndex, 1);
    expect(find.byKey(const ValueKey('am_gear_gate')), findsOneWidget);
  });

  testWidgets('richiede esattamente tre marce e un indice valido', (
    tester,
  ) async {
    expect(
      () => AmGearPeriodSelector(
        labels: const ['Giornaliero', 'Mensile'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
    expect(
      () => AmGearPeriodSelector(
        labels: const ['Giornaliero', 'Mensile', 'Annuale'],
        selectedIndex: 3,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('mantiene visibile il percorso con la palette chiara', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: AmGearPeriodSelector(
            labels: const ['Giornaliero', 'Mensile', 'Annuale'],
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
