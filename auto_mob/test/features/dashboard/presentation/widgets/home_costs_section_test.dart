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
    ValueChanged<MaintenanceCostPeriod>? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AmTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeCostsSection(
            selectedPeriod: period,
            maintenanceCostCents: maintenanceCostCents,
            onPeriodChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  testWidgets('mostra periodi, riepiloghi costo e timeline demo', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.byType(AmInsetTabBar), findsOneWidget);
    expect(find.text('Giornaliero'), findsOneWidget);
    expect(find.text('Mensile'), findsOneWidget);
    expect(find.text('Annuale'), findsOneWidget);
    expect(find.text('Manutenzione'), findsOneWidget);
    expect(find.text('Carburante'), findsOneWidget);
    expect(find.text('Documenti'), findsOneWidget);
    expect(find.text('€ 100,00'), findsOneWidget);
    expect(find.text('-'), findsNWidgets(2));
    expect(find.text('Scaduto'), findsOneWidget);
    expect(find.text('Pagato'), findsNWidgets(3));
    expect(find.text('In corso'), findsOneWidget);
    final colors = AmThemeColors.of(
      tester.element(find.byType(HomeCostsSection)),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.car_repair_outlined).first).color,
      colors.textSecondary,
    );
    expect(
      tester
          .widget<Scrollable>(
            find.descendant(
              of: find.byKey(const Key('home-costs-year-timeline')),
              matching: find.byType(Scrollable),
            ),
          )
          .axisDirection,
      AxisDirection.right,
    );
  });

  testWidgets('inoltra al bloc il nuovo periodo selezionato', (tester) async {
    MaintenanceCostPeriod? selected;
    await pumpSection(tester, onChanged: (value) => selected = value);

    await tester.tap(find.text('Annuale'));
    await tester.pumpAndSettle();

    expect(selected, MaintenanceCostPeriod.annual);
  });
}
