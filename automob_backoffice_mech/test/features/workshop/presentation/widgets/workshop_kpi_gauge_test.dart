import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_kpi_gauge.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildGauge({required num value, required num maximum}) => MaterialApp(
    theme: ThemeData(extensions: const [AmThemeColors.dark]),
    home: Scaffold(
      body: WorkshopKpiGauge(
        label: 'Fatturato',
        value: value,
        maximum: maximum,
        valueFormatter: (amount) => '€ ${amount.round()}',
      ),
    ),
  );

  testWidgets('calcola la percentuale e mostra solo il massimo laterale', (
    tester,
  ) async {
    await tester.pumpWidget(buildGauge(value: 25, maximum: 100));

    final semantics = tester.getSemantics(find.byType(WorkshopKpiGauge));
    expect(semantics.value, contains('25%'));
    expect(find.text('€ 0'), findsOneWidget);
    expect(find.text('€ 100'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WorkshopKpiGauge),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('workshop_kpi_value_outside_dial')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('am_kpi_value')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    final intermediate = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('am_kpi_value')),
        matching: find.byType(Text),
      ),
    );
    expect(intermediate.data, isNot(anyOf('€ 0', '€ 25')));

    await tester.pumpAndSettle();
    expect(find.text('€ 25'), findsOneWidget);
  });

  testWidgets('limita la lancetta fra zero e cento per cento', (tester) async {
    await tester.pumpWidget(buildGauge(value: 140, maximum: 100));
    expect(
      tester.getSemantics(find.byType(WorkshopKpiGauge)).value,
      contains('100%'),
    );

    await tester.pumpWidget(buildGauge(value: -10, maximum: 100));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(WorkshopKpiGauge)).value,
      contains('0%'),
    );
  });

  testWidgets('gestisce un massimo nullo senza valori non finiti', (
    tester,
  ) async {
    await tester.pumpWidget(buildGauge(value: 10, maximum: 0));
    expect(
      tester.getSemantics(find.byType(WorkshopKpiGauge)).value,
      contains('0%'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra etichetta ridotta e valore attuale dentro il quadrante', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(165, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildGauge(value: 90, maximum: 100));
    await tester.pumpAndSettle();

    final labelFinder = find.byKey(const ValueKey('am_kpi_heading'));
    final currentValueFinder = find.byKey(const ValueKey('am_kpi_value'));
    final label = tester.widget<Text>(
      find.descendant(of: labelFinder, matching: find.byType(Text)),
    );
    final valueText = tester.widget<Text>(
      find.descendant(of: currentValueFinder, matching: find.byType(Text)),
    );
    expect(label.style?.fontSize, 7.5);
    expect(
      tester.getTopLeft(currentValueFinder).dy,
      greaterThan(tester.getTopLeft(labelFinder).dy),
    );
    expect(valueText.textAlign, TextAlign.center);
    expect(valueText.style?.fontSize, 10.5);
    expect(valueText.style?.color, AmThemeColors.dark.textPrimary);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'numero e lancetta arretrano insieme se valore e massimo calano',
    (tester) async {
      const valueKey = ValueKey('am_kpi_value');
      await tester.binding.setSurfaceSize(const Size(220, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildGauge(value: 90, maximum: 100));
      await tester.pumpAndSettle();
      final initialDial = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('am_kpi_dial')),
      );
      final initialProgress =
          (initialDial.painter as dynamic).progress as double;

      await tester.pumpWidget(buildGauge(value: 10, maximum: 20));
      await tester.pump(const Duration(milliseconds: 400));

      final movingValue = tester.widget<Text>(
        find.descendant(of: find.byKey(valueKey), matching: find.byType(Text)),
      );
      final movingDial = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('am_kpi_dial')),
      );
      final movingProgress = (movingDial.painter as dynamic).progress as double;
      expect(movingValue.data, isNot(anyOf('€ 90', '€ 10')));
      expect(movingProgress, lessThan(initialProgress));
      expect(movingProgress, greaterThan(0.5));
    },
  );
}
