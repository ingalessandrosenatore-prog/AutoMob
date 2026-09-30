import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra gerarchia, metadati e indicatore di apertura', (
    tester,
  ) async {
    final entry = WorkLogEntry(
      id: 'work-layout',
      vehicleId: 'vehicle-1',
      type: 'freni',
      customName: 'Pastiglie anteriori',
      serviceKm: 165000,
      serviceDate: DateTime(2026, 8, 24),
      notes: 'Controllare anche i dischi',
      hasWorkshop: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: WorkLogItemCard(entry: entry, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Pastiglie anteriori'), findsOneWidget);
    expect(find.text('24/08/2026'), findsOneWidget);
    expect(find.text('165.000 km'), findsOneWidget);
    expect(find.text('Controllare anche i dischi'), findsOneWidget);
    expect(find.text('Officina'), findsOneWidget);
    expect(find.byKey(const Key('work-log-item-type-icon')), findsOneWidget);
    expect(find.byKey(const Key('work-log-item-open-icon')), findsOneWidget);
    final colors = AmThemeColors.light;
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('work-log-item-card-surface')),
    );
    final borderDecoration = surface.decoration as ShapeDecoration;
    expect(borderDecoration.gradient, colors.cardBorderGradient);
    expect(borderDecoration.shadows, colors.cardShadows);
    expect(
      tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(const Key('work-log-item-card-surface')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .any((decoration) => decoration.color == colors.surface),
      isTrue,
    );
  });

  testWidgets('le card entrano da destra una dopo l altra', (tester) async {
    WorkLogEntry entry(int index) => WorkLogEntry(
      id: 'work-$index',
      vehicleId: 'vehicle-1',
      type: 'tagliando',
      serviceKm: 42000 + index,
      serviceDate: DateTime(2026, 8, 24),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              WorkLogItemCard(entry: entry(0), entranceIndex: 0, onTap: () {}),
              WorkLogItemCard(entry: entry(1), entranceIndex: 1, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    Offset position(int index) => tester
        .widget<SlideTransition>(
          find.byKey(Key('work-log-card-entrance-$index')),
        )
        .position
        .value;

    expect(position(0).dx, greaterThan(0));
    expect(position(1).dx, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(position(0).dx, lessThan(position(1).dx));
    await tester.pumpAndSettle();
    expect(position(0).dx, closeTo(0, 0.001));
    expect(position(1).dx, closeTo(0, 0.001));
  });
}
