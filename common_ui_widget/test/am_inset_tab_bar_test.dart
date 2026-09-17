import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact dark pill is narrower and has no visible border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: Column(
            children: [
              AmInsetTabBar(
                compact: true,
                labels: const ['Giorno', 'Mensile', 'Anno'],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    final selected = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    final decoration = selected.decoration! as BoxDecoration;
    expect((decoration.border! as Border).top.color, Colors.transparent);
    expect(selected.margin, const EdgeInsets.symmetric(horizontal: 10));
    final material = find.descendant(
      of: find.byType(AnimatedContainer).first,
      matching: find.byType(Material),
    );
    expect(tester.getSize(material).height, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact light selector has a soft recess and taller container', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AmInsetTabBar(
                compact: true,
                labels: const ['Giorno', 'Mensile', 'Anno'],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(AmInsetTabBar)).height, 59);
    final colors = AmTheme.light.extension<AmThemeColors>()!;
    final recess = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ClipRRect),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final gradient =
        (recess.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(gradient.colors.first, colors.surfaceDeep);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports selection and exposes the controlled selected state', (
    tester,
  ) async {
    var selection = 0;
    Widget build(int index) => MaterialApp(
      theme: ThemeData(extensions: const [AmThemeColors.dark]),
      home: Scaffold(
        body: AmInsetTabBar(
          labels: const ['Giorno', 'Mensile', 'Anno'],
          selectedIndex: index,
          onChanged: (value) => selection = value,
        ),
      ),
    );
    await tester.pumpWidget(build(0));
    await tester.tap(find.text('Anno'));
    expect(selection, 2);
    await tester.pumpWidget(build(selection));
    await tester.pumpAndSettle();
    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected == true);
    expect(selected, hasLength(1));
    expect(
      find.descendant(
        of: find.byWidget(selected.single),
        matching: find.text('Anno'),
      ),
      findsOneWidget,
    );
  });
}
