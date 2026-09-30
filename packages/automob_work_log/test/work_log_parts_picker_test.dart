import 'package:automob_work_log/src/domain/work_log_parts_catalog.dart';
import 'package:automob_work_log/src/presentation/work_log_part_icons.dart';
import 'package:automob_work_log/src/presentation/work_log_parts_picker.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra una categoria alla volta ma la ricerca usa tutto il catalogo',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      WorkLogPartCategory? category = WorkLogPartCategory.brakes;
      String query = '';

      Widget buildPicker() => MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => WorkLogPartsPicker(
              selectedParts: const [],
              query: query,
              selectedCategory: category,
              onQueryChanged: (value) => setState(() => query = value),
              onCategoryChanged: (value) => setState(() => category = value),
              onPartToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildPicker());

      final brakesChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('work-log-part-category-freni')),
      );
      expect(brakesChip.selected, isTrue);
      expect(find.byKey(const ValueKey('work-log-part-20')), findsOneWidget);
      expect(find.byKey(const ValueKey('work-log-part-7')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('work-log-part-category-motore')),
      );
      await tester.pump();
      expect(category, WorkLogPartCategory.engine);
      expect(find.byKey(const ValueKey('work-log-part-7')), findsOneWidget);
      expect(find.byKey(const ValueKey('work-log-part-20')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('work-log-parts-search')),
        'Pastiglie',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('work-log-part-20')), findsOneWidget);
      expect(category, WorkLogPartCategory.engine);

      final grid = tester.widget<GridView>(
        find.byKey(const Key('work-log-parts-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
      expect(delegate.crossAxisSpacing, 6);
      expect(delegate.mainAxisSpacing, 6);
      expect(tester.takeException(), isNull);
    },
  );

  test('ogni ricambio usa una propria icona 2D', () {
    final partIdsByIcon = <List<List<dynamic>>, List<int>>{};
    for (var partId = 1; partId <= 95; partId++) {
      partIdsByIcon.putIfAbsent(workLogPartIcon(partId), () => []).add(partId);
    }
    final duplicates = partIdsByIcon.values.where((ids) => ids.length > 1);
    expect(duplicates, isEmpty, reason: 'Icone duplicate: $duplicates');
  });
}
