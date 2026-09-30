import 'package:auto_mob_v1/features/dashboard/presentation/widgets/home_costs_section.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_mob_v1/features/dashboard/domain/entities/maintenance_cost_period.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester, {
    MaintenanceCostPeriod period = MaintenanceCostPeriod.monthly,
    int maintenanceCostCents = 10000,
    int fuelCostCents = 7500,
    DateTime? now,
    ValueChanged<MaintenanceCostPeriod>? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AmTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeCostsSection(
            selectedPeriod: period,
            maintenanceCostCents: maintenanceCostCents,
            fuelCostCents: fuelCostCents,
            now: now,
            onPeriodChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  testWidgets('mostra tre tachimetri compatti con icone e dati disponibili', (
    tester,
  ) async {
    await pumpSection(tester, now: DateTime(2024, 2, 15, 12));
    await tester.pumpAndSettle();

    expect(find.byType(AmInsetTabBar), findsNothing);
    expect(find.byType(AmGearPeriodSelector), findsOneWidget);
    expect(find.byType(AmKpiGauge), findsNWidgets(3));
    expect(find.text('GIORNALIERO'), findsOneWidget);
    expect(find.text('MENSILE'), findsOneWidget);
    expect(find.text('ANNUALE'), findsOneWidget);
    expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.text('€ 100,00'), findsOneWidget);
    expect(find.text('€ 75,00'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('Manutenzione'), findsNothing);
    final gaugesBottom = tester.getBottomLeft(find.byType(AmKpiGauge).last);
    final selectorTop = tester.getTopLeft(find.byType(AmGearPeriodSelector));
    expect(selectorTop.dy - gaugesBottom.dy, closeTo(4, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantiene i tre tachimetri leggibili su una home stretta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSection(tester, now: DateTime(2024, 2, 15, 12));
    await tester.pumpAndSettle();

    expect(find.byType(AmKpiGauge), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('riempie il quadrante in base al tempo del periodo', (
    tester,
  ) async {
    final now = DateTime(2024, 2, 15, 12);

    Future<double> progressFor(MaintenanceCostPeriod period) async {
      await pumpSection(tester, period: period, now: now);
      await tester.pumpAndSettle();
      final gauge = find.byKey(const ValueKey('home_cost_gauge_0'));
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: gauge,
          matching: find.byKey(const ValueKey('am_kpi_dial')),
        ),
      );
      return (paint.painter as dynamic).progress as double;
    }

    expect(await progressFor(MaintenanceCostPeriod.daily), closeTo(0.5, 0.001));
    expect(
      await progressFor(MaintenanceCostPeriod.monthly),
      closeTo(15 / 29, 0.001),
    );
    expect(
      await progressFor(MaintenanceCostPeriod.annual),
      closeTo(2 / 12, 0.001),
    );
  });

  testWidgets('mostra trattino anche per manutenzione senza dati', (
    tester,
  ) async {
    await pumpSection(tester, maintenanceCostCents: 0);
    await tester.pumpAndSettle();

    expect(find.text('-'), findsNWidgets(2));
  });

  testWidgets('inoltra al bloc il nuovo periodo selezionato', (tester) async {
    MaintenanceCostPeriod? selected;
    await pumpSection(tester, onChanged: (value) => selected = value);

    await tester.tap(find.text('ANNUALE'));
    await tester.pumpAndSettle();

    expect(selected, MaintenanceCostPeriod.annual);
  });
}
