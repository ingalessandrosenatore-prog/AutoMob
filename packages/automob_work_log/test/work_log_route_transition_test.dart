import 'package:automob_work_log/src/presentation/work_log_route_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la route WorkLog usa opacity senza traslare il glass', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
    addTearDown(animation.dispose);
    final route = WorkLogSlidePageRoute<void>(
      builder: (_, _) => const SizedBox(key: Key('work-log-page')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => route.transitionsBuilder(
            context,
            animation,
            kAlwaysDismissedAnimation,
            const SizedBox(key: Key('work-log-page')),
          ),
        ),
      ),
    );

    final fadeFinder = find.byKey(
      const Key('work-log-route-opacity-transition'),
    );
    expect(fadeFinder, findsOneWidget);
    expect(
      find.descendant(of: fadeFinder, matching: find.byType(SlideTransition)),
      findsNothing,
    );
    expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 0);

    animation.value = 0.75;
    await tester.pump();

    expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1);
    expect(animation.value, lessThan(1));

    animation.value = 1;
    animation.reverse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(
      tester.widget<FadeTransition>(fadeFinder).opacity.value,
      inInclusiveRange(0, 1),
    );
    expect(animation.value, greaterThan(0));
    await tester.pumpAndSettle();
  });
}
