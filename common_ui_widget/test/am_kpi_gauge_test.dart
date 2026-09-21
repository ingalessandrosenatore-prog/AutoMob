import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildGauge(Widget gauge) => MaterialApp(
    theme: AmTheme.dark,
    home: Scaffold(
      body: Center(child: SizedBox(width: 180, child: gauge)),
    ),
  );

  testWidgets('accetta un titolo e calcola la corsa dal massimo', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGauge(
        AmKpiGauge(
          label: 'Fatturato',
          value: 25,
          maximum: 100,
          valueFormatter: (value) => '€ ${value.round()}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FATTURATO'), findsOneWidget);
    expect(find.text('€ 25'), findsOneWidget);
    expect(find.text('€ 100'), findsOneWidget);
    expect(find.byKey(const ValueKey('am_kpi_tick_ring')), findsOneWidget);
    expect(find.byKey(const ValueKey('am_kpi_outer_ring')), findsOneWidget);
    final colors = AmThemeColors.of(tester.element(find.byType(AmKpiGauge)));
    final dialFinder = find.byKey(const ValueKey('am_kpi_dial'));
    final dial = tester.widget<CustomPaint>(dialFinder).painter!;
    expect(
      (Canvas canvas) => dial.paint(canvas, tester.getSize(dialFinder)),
      paints
        ..arc(color: colors.accent.withValues(alpha: 0.24), strokeWidth: 3)
        ..arc(
          color: colors.accent.withValues(alpha: 0.62),
          strokeWidth: 14,
          hasMaskFilter: true,
        ),
    );
    final outerRingFinder = find.byKey(const ValueKey('am_kpi_outer_ring'));
    final outerRing = tester.widget<CustomPaint>(outerRingFinder).painter!;
    void paintOuterRing(Canvas canvas) =>
        outerRing.paint(canvas, tester.getSize(outerRingFinder));
    expect(paintOuterRing, paintsExactlyCountTimes(#drawArc, 1));
    expect(
      paintOuterRing,
      paints..arc(
        color: colors.border.withValues(alpha: 0.72),
        hasMaskFilter: false,
      ),
    );
    expect(tester.getSemantics(find.byType(AmKpiGauge)).value, contains('25%'));
  });

  testWidgets('accetta una piccola icona e mostra trattino senza valore', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGauge(
        AmKpiGauge(
          icon: Icons.local_gas_station_outlined,
          semanticLabel: 'Carburante',
          value: null,
          progress: 0.5,
          compact: true,
          valueFormatter: (value) => '€ ${value.round()}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconFinder = find.byIcon(Icons.local_gas_station_outlined);
    expect(iconFinder, findsOneWidget);
    expect(
      tester.widget<Icon>(iconFinder).color,
      AmThemeColors.of(tester.element(find.byType(AmKpiGauge))).accent,
    );
    expect(find.text('-'), findsOneWidget);
    expect(find.byKey(const ValueKey('am_kpi_maximum')), findsNothing);
    expect(tester.getSize(find.byType(AmKpiGauge)).height, 108);
    expect(tester.getSemantics(find.byType(AmKpiGauge)).label, 'Carburante');
  });
}
