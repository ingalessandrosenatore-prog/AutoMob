import 'package:automob_backoffice_mech/features/subscription/domain/entities/subscription_overview.dart';
import 'package:automob_backoffice_mech/features/subscription/presentation/pages/subscription_plan_page.dart';
import 'package:automob_backoffice_mech/features/subscription/presentation/widgets/subscription_billing_selector.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra i tre piani mensili e il contatto assistenza', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AmTheme.dark, home: const SubscriptionPlanPage()),
    );

    expect(find.text('Scegli il piano giusto per la tua officina'), findsOne);
    expect(find.text('Base'), findsOne);
    expect(find.text('Premium'), findsOne);
    expect(find.text('€25,89'), findsOne);
    expect(find.text('€41,99'), findsOne);
    expect(find.text('30 veicoli'), findsOne);
    expect(find.text('Fino a 100 veicoli'), findsOne);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription_plan_elite')),
      500,
    );
    expect(find.text('Elite'), findsOne);
    expect(find.text('€110,99'), findsOne);
    expect(find.text('Veicoli illimitati'), findsOne);
    expect(find.text('CONTATTACI'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra prezzi mensili scontati del dieci per cento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AmTheme.light, home: const SubscriptionPlanPage()),
    );

    await tester.tap(find.text('Annuale'));
    await tester.pump();

    expect(find.text('10%'), findsOne);
    expect(find.text('€23,30'), findsOne);
    expect(find.text('€290,68'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('subscription_plan_base')),
        matching: find.text('-10%'),
      ),
      findsOne,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription_plan_premium')),
      320,
    );
    expect(find.text('€37,79'), findsOne);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription_plan_elite')),
      500,
    );
    expect(find.text('€99,89'), findsOne);
    expect(find.text('€1.231,88'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('i piani superiori includono quelli precedenti', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AmTheme.dark, home: const SubscriptionPlanPage()),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription_plan_premium')),
      320,
    );
    expect(find.text('Tutto quello del Base'), findsOne);
    expect(find.text('Fino a 100 veicoli'), findsOne);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription_plan_elite')),
      500,
    );
    expect(find.text('Tutto quello del Premium'), findsOne);
    expect(find.text('Veicoli illimitati'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('apre WhatsApp con piano e fatturazione selezionati', (
    tester,
  ) async {
    Uri? launchedUri;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionPlanPage(
          uriLauncher: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Annuale'));
    await tester.pump();
    final premium = find.byKey(const ValueKey('subscription_plan_premium'));
    await tester.drag(
      find.byKey(const ValueKey('subscription_plan_list')),
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();
    await tester.tap(premium);
    await tester.pumpAndSettle();

    expect(
      launchedUri,
      Uri.https('wa.me', '/393476505572', {
        'text':
            'Ciao, vorrei attivare il piano Premium con fatturazione '
            'annuale e ricevere maggiori informazioni.',
      }),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('il contatto apre la richiesta generica su WhatsApp', (
    tester,
  ) async {
    Uri? launchedUri;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionPlanPage(
          uriLauncher: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('CONTATTACI'));
    await tester.pump();

    expect(launchedUri?.host, 'wa.me');
    expect(launchedUri?.path, '/393476505572');
    expect(
      launchedUri?.queryParameters['text'],
      'Ciao, vorrei ricevere maggiori informazioni sugli abbonamenti AutoMob.',
    );
  });

  testWidgets('mostra il piano corrente e permette di aggiornare gli altri', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: SubscriptionPlanPage(
          currentOverview: SubscriptionOverview(
            workshopName: 'Officina Rossi',
            mechanicCode: '482913',
            plan: SubscriptionPlan.premium,
            billingCycle: SubscriptionBillingCycle.yearly,
            status: SubscriptionStatus.active,
            expiresAt: DateTime(2027, 1, 15),
            daysRemaining: 145,
            linkedVehicles: 22,
          ),
        ),
      ),
    );

    expect(find.text('IL TUO PIANO'), findsOne);
    expect(find.text('AutoMob Premium'), findsOne);
    expect(find.text('Altri piani'), findsOne);
    expect(
      tester
          .widget<SubscriptionBillingSelector>(
            find.byType(SubscriptionBillingSelector),
          )
          .selected,
      SubscriptionBillingCycle.yearly,
    );
    expect(
      find.byKey(const ValueKey('subscription_plan_premium')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('subscription_plan_base')),
        matching: find.text('AGGIORNA'),
      ),
      findsOne,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription_plan_elite')),
      500,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('subscription_plan_elite')),
        matching: find.text('AGGIORNA'),
      ),
      findsOne,
    );
    expect(find.text('INIZIA LA PROVA GRATUITA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
