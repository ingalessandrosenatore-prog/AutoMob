import 'package:automob_backoffice_mech/features/subscription/domain/entities/subscription_overview.dart';
import 'package:automob_backoffice_mech/features/subscription/presentation/widgets/subscription_overview_view.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final overview = SubscriptionOverview(
    workshopName: 'Officina Rossi',
    mechanicCode: '482913',
    plan: SubscriptionPlan.premium,
    status: SubscriptionStatus.active,
    expiresAt: _expiry,
    daysRemaining: 118,
    linkedVehicles: 12,
  );

  testWidgets('mostra codice piano scadenza e veicoli su mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionOverviewView(
          overview: overview,
          onRefresh: () {},
          onCopyCode: () {},
          onPlanPressed: () {},
          onProfilePressed: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('subscription_soft_edge_blur')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('subscription_app_bar')), findsOneWidget);
    expect(find.byTooltip('Aggiorna dati'), findsOneWidget);
    expect(find.byTooltip('Copia codice'), findsOneWidget);
    expect(find.text('AutoMob Premium'), findsOneWidget);
    expect(find.byKey(const ValueKey('mechanic_code_482913')), findsOneWidget);
    expect(find.text('18 dicembre 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('linked_vehicles_12')), findsOneWidget);
    expect(find.textContaining(' / 100'), findsOneWidget);
    expect(find.text('88 posti ancora disponibili'), findsOneWidget);
    final vehicleCardSurface = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('vehicle_usage_card')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final vehicleCardDecoration =
        vehicleCardSurface.decoration as BoxDecoration;
    final cardContext = tester.element(
      find.byKey(const ValueKey('vehicle_usage_card')),
    );
    final cardColors = AmThemeColors.of(cardContext);
    expect(vehicleCardDecoration.color, cardColors.surface);
    expect(vehicleCardDecoration.color, isNot(cardColors.cardBackground));
    expect(vehicleCardDecoration.boxShadow, isNull);
    final vehicleIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('vehicle_usage_card')),
        matching: find.byIcon(Icons.directions_car_rounded),
      ),
    );
    expect(vehicleIcon.color, cardColors.accent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa due colonne senza overflow quando c e spazio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionOverviewView(
          overview: overview,
          onRefresh: () {},
          onCopyCode: () {},
          onPlanPressed: () {},
          onProfilePressed: () {},
        ),
      ),
    );

    final codeTop = tester.getTopLeft(
      find.byKey(const ValueKey('mechanic_code_card')),
    );
    final usageTop = tester.getTopLeft(
      find.byKey(const ValueKey('vehicle_usage_card')),
    );
    expect(codeTop.dy, usageTop.dy);
    expect(codeTop.dx, lessThan(usageTop.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('i soft button inoltrano aggiorna e copia', (tester) async {
    var refreshCount = 0;
    var copyCount = 0;
    var planCount = 0;
    var profileCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: SubscriptionOverviewView(
          overview: overview,
          onRefresh: () => refreshCount++,
          onCopyCode: () => copyCount++,
          onPlanPressed: () => planCount++,
          onProfilePressed: () => profileCount++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Aggiorna dati'));
    await tester.pump();
    await tester.tap(find.byTooltip('Copia codice'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subscription_plan_card')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('workshop_summary_card')),
    );
    await tester.tap(find.byKey(const ValueKey('workshop_summary_card')));
    await tester.pump();

    expect(refreshCount, 1);
    expect(copyCount, 1);
    expect(planCount, 1);
    expect(profileCount, 1);
    final title = tester.widget<Text>(find.text('Servizi'));
    final titleContext = tester.element(find.text('Servizi'));
    expect(title.style?.color, AmThemeColors.of(titleContext).textPrimary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra lo stato senza piano senza inventare una scadenza', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionOverviewView(
          overview: const SubscriptionOverview(
            workshopName: 'Officina Test',
            mechanicCode: '482913',
            plan: SubscriptionPlan.none,
            status: SubscriptionStatus.inactive,
            expiresAt: null,
            daysRemaining: 0,
            linkedVehicles: 0,
          ),
          onRefresh: () {},
          onCopyCode: () {},
          onPlanPressed: () {},
          onProfilePressed: () {},
        ),
      ),
    );

    expect(find.text('Nessun piano attivo'), findsOneWidget);
    expect(
      find.text('Inizia gratis e disdici quando vuoi, senza vincoli.'),
      findsOneWidget,
    );
    expect(find.text('IL TUO PIANO'), findsNothing);
    expect(find.text('Non impostata'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantiene visibile un piano conosciuto ma non attivo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionOverviewView(
          overview: const SubscriptionOverview(
            workshopName: 'Officina Test',
            mechanicCode: '482913',
            plan: SubscriptionPlan.premium,
            billingCycle: SubscriptionBillingCycle.monthly,
            status: SubscriptionStatus.inactive,
            expiresAt: null,
            daysRemaining: 0,
            linkedVehicles: 12,
          ),
          onRefresh: () {},
          onCopyCode: () {},
          onPlanPressed: () {},
          onProfilePressed: () {},
        ),
      ),
    );

    expect(find.text('IL TUO PIANO'), findsOne);
    expect(find.text('AutoMob Premium'), findsOne);
    expect(find.text('Non attivo'), findsOne);
    expect(find.text('Nessun piano attivo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra il limite illimitato per il piano Elite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionOverviewView(
          overview: const SubscriptionOverview(
            workshopName: 'Officina Test',
            mechanicCode: '482913',
            plan: SubscriptionPlan.elite,
            status: SubscriptionStatus.active,
            expiresAt: null,
            daysRemaining: 0,
            linkedVehicles: 120,
          ),
          onRefresh: () {},
          onCopyCode: () {},
          onPlanPressed: () {},
          onProfilePressed: () {},
        ),
      ),
    );

    expect(find.textContaining(' / ∞'), findsOneWidget);
    expect(find.text('Posti illimitati'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _expiry = DateTime(2026, 12, 18);
