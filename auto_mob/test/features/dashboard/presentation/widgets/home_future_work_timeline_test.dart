import 'package:auto_mob_v1/features/dashboard/presentation/widgets/home_future_work_timeline.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_summary.dart';

void main() {
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
      find.text(
        '13 SET 2026  ·  DA EFFETTUARE ENTRO 18 SET 2026',
        findRichText: true,
      ),
      findsOneWidget,
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
        find.text(
          '17 SET 2026  ·  DA EFFETTUARE ENTRO 02 OTT 2026',
          findRichText: true,
        ),
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
