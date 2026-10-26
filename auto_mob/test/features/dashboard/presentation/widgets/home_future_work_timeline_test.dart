import 'package:auto_mob_v1/features/dashboard/presentation/widgets/home_future_work_timeline.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_summary.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/warning_light_observation.dart';

void main() {
  testWidgets('data e km precedono il messaggio di bordo e le spie', (
    tester,
  ) async {
    final summary = FutureWorkSummary(
      id: 'i1',
      recordId: 'r1',
      vehicleId: 'v1',
      description: 'Percezione utente',
      onboardMessage: 'Messaggio di bordo',
      reportedKm: 189598,
      warningLights: const [
        WarningLightObservation(code: 'S03', color: 'amber'),
      ],
      registeredAt: DateTime(2026, 10, 26),
      reminderDate: DateTime(2027),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: HomeFutureWorkTimeline.fromSummaries(
            summaries: [summary],
            onDone: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Percezione utente'), findsNothing);
    final header = find.byKey(const ValueKey('report-date-km-r1'));
    final title = find.text('Messaggio di bordo');
    final lights = find.byType(AmWarningLights);
    expect(
      tester.getTopLeft(title).dy,
      greaterThan(tester.getBottomLeft(header).dy),
    );
    expect(
      tester.getTopLeft(lights).dy,
      greaterThan(tester.getBottomLeft(title).dy),
    );
    expect(
      tester.getTopLeft(find.text('Segna come risolta')).dy,
      greaterThan(tester.getBottomLeft(lights).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra i lavori futuri su una timeline allineata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeFutureWorkTimeline.demo(
              onReportProblem: () => pressed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('LAVORI FUTURI'), findsOneWidget);
    expect(find.text('Cambio pastiglie posteriori'), findsOneWidget);
    expect(
      find.text('13 SET 2026  ·  km non rilevati', findRichText: true),
      findsNWidgets(2),
    );
    expect(find.text('Tagliando periodico'), findsOneWidget);
    expect(find.text('Segnala problema'), findsOneWidget);

    final first = tester.getCenter(
      find.byKey(const ValueKey('future-work-marker-0')),
    );
    final second = tester.getCenter(
      find.byKey(const ValueKey('future-work-marker-1')),
    );
    final third = tester.getCenter(
      find.byKey(const ValueKey('future-work-marker-2')),
    );
    expect(second.dx, closeTo(first.dx, 0.01));
    expect(third.dx, closeTo(first.dx, 0.01));
    expect(second.dy, greaterThan(first.dy));
    expect(third.dy, greaterThan(second.dy));

    await tester.tap(find.byKey(const ValueKey('report-problem-button')));
    await tester.pump();
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mostra i dati reali formattati e mantiene il pulsante a lista vuota',
    (tester) async {
      final summary = FutureWorkSummary(
        id: 'i1',
        recordId: 'r1',
        vehicleId: 'v1',
        description: 'Controllare la batteria',
        reportedKm: 189598,
        registeredAt: DateTime(2026, 9, 17),
        reminderDate: DateTime(2026, 10, 2),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: HomeFutureWorkTimeline.fromSummaries(summaries: [summary]),
          ),
        ),
      );

      expect(find.text('Controllare la batteria'), findsOneWidget);
      expect(
        find.text('17 SET 2026  ·  189.598 km', findRichText: true),
        findsOneWidget,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: HomeFutureWorkTimeline.fromSummaries(
              summaries: const [],
              onReportProblem: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('future-work-empty')), findsOneWidget);
      expect(find.text('Segnala problema'), findsOneWidget);
    },
  );
}
