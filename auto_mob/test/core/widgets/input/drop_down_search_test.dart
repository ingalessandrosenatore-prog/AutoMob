import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  const targetKey = ValueKey('am-dropdown-search-target');
  const panelKey = ValueKey('am-dropdown-search-panel');

  Future<void> pumpDropdown(
    WidgetTester tester, {
    required double top,
    String? value,
    ValueChanged<String?>? onChanged,
  }) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.only(top: top),
            child: SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AmDropdownSearch<String>(
                    label: 'Anno',
                    items: const ['2026', '2025', '2024'],
                    value: value,
                    itemLabelBuilder: (item) => item,
                    onChanged: onChanged ?? (_) {},
                    placeholder: 'Scegli anno',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('apre il pannello sotto quando lo spazio e sufficiente', (
    tester,
  ) async {
    await pumpDropdown(tester, top: 20);

    await tester.tap(find.text('Scegli anno'));
    await tester.pump();

    final triggerRect = tester.getRect(find.byKey(targetKey));
    final panelRect = tester.getRect(find.byKey(panelKey));

    expect(panelRect.top, closeTo(triggerRect.bottom + 4, 0.01));
  });

  testWidgets('apre il pannello sopra quando sotto non c e spazio', (
    tester,
  ) async {
    await pumpDropdown(tester, top: 470);

    await tester.tap(find.text('Scegli anno'));
    await tester.pump();

    final triggerRect = tester.getRect(find.byKey(targetKey));
    final panelRect = tester.getRect(find.byKey(panelKey));

    expect(panelRect.bottom, closeTo(triggerRect.top - 4, 0.01));
    expect(panelRect.top, greaterThanOrEqualTo(8));
  });

  testWidgets('il pannello resta collegato al campo durante lo scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 140),
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      AmDropdownSearch<String>(
                        label: 'Anno',
                        items: const ['2026', '2025', '2024'],
                        itemLabelBuilder: (item) => item,
                        onChanged: (_) {},
                        placeholder: 'Scegli anno',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 700),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scegli anno'));
    await tester.pump();
    scrollController.jumpTo(20);
    await tester.pump();

    final triggerRect = tester.getRect(find.byKey(targetKey));
    final panelRect = tester.getRect(find.byKey(panelKey));
    expect(panelRect.top, closeTo(triggerRect.bottom + 4, 0.01));
  });

  testWidgets('usa il glass, riduce Cerca e non mostra il check selezionato', (
    tester,
  ) async {
    String? changedValue;
    await pumpDropdown(
      tester,
      top: 20,
      value: '2026',
      onChanged: (value) => changedValue = value,
    );

    await tester.tap(find.text('2026').first);
    await tester.pump();

    final searchIconFinder = find.byWidgetPredicate(
      (widget) =>
          widget is HugeIcon && widget.icon == HugeIcons.strokeRoundedSearch01,
    );
    final searchIcon = tester.widget<HugeIcon>(searchIconFinder);
    expect(searchIcon.size, 16);
    expect(tester.getSize(searchIconFinder), const Size.square(16));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is HugeIcon &&
            widget.icon == HugeIcons.strokeRoundedValidation,
      ),
      findsNothing,
    );

    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
    final glass = tester.widget<OCLiquidGlass>(find.byType(OCLiquidGlass));
    expect(
      glass.color,
      AmThemeColors.dark.surfaceRaised.withValues(alpha: 0.8),
    );

    await tester.tap(find.text('2025'));
    await tester.pump();
    expect(changedValue, '2025');
    expect(find.byKey(panelKey), findsNothing);
  });
}
