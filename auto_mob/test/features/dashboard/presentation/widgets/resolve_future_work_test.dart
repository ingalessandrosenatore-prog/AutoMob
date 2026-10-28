import 'package:auto_mob_v1/features/dashboard/presentation/widgets/resolve_future_work.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_summary.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/warning_light_observation.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  final report = FutureWorkSummary(
    id: 'i1',
    recordId: 'r1',
    vehicleId: 'v1',
    description: 'Perde potenza',
    onboardMessage: 'Controllare motore',
    warningLights: const [
      WarningLightObservation(code: 'S10', color: 'amber'),
      WarningLightObservation(code: 'S10', color: 'amber', flashing: true),
    ],
    registeredAt: DateTime(2026),
    reminderDate: DateTime(2027),
  );

  for (final result in [false, true]) {
    testWidgets('precompila il lavoro e risolve solo se salvato: $result', (
      tester,
    ) async {
      var resolved = 0;
      Map<String, dynamic>? extra;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => resolveFutureWork(
                  context,
                  report: report,
                  vehicle: vehicleFixture(id: 'v1'),
                  onDisappeared: () => fail('Percorso errato'),
                  onWorkSaved: () => resolved++,
                ),
                child: const Text('Risolvi'),
              ),
            ),
          ),
          GoRoute(
            path: '/work',
            name: 'aggiungi_lavoro',
            builder: (context, state) {
              extra = state.extra as Map<String, dynamic>;
              return Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(result),
                  child: const Text('Termina'),
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
      );
      await tester.tap(find.text('Risolvi'));
      await tester.pumpAndSettle();
      expect(resolved, 0);
      expect(find.byType(AmStatusDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Ho eseguito il lavoro'));
      await tester.pumpAndSettle();
      expect(extra?['initialWorkType'], 'altro');
      expect(extra?['initialCustomName'], 'Avaria motore');
      expect(extra?['initialNotes'], 'Controllare motore');
      expect(extra?['sourceReportId'], 'r1');
      expect(resolved, 0);
      await tester.tap(find.text('Termina'));
      await tester.pumpAndSettle();
      expect(resolved, result ? 1 : 0);
    });
  }

  testWidgets('annullare non chiude, problema scomparso chiude senza lavoro', (
    tester,
  ) async {
    var disappeared = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => resolveFutureWork(
                context,
                report: report,
                vehicle: vehicleFixture(id: 'v1'),
                onDisappeared: () => disappeared++,
                onWorkSaved: () => fail('Nessun lavoro eseguito'),
              ),
              child: const Text('Risolvi'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Risolvi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(disappeared, 0);
    await tester.tap(find.text('Risolvi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('La spia / il problema è scomparso'));
    await tester.pumpAndSettle();
    expect(disappeared, 1);
  });
}
