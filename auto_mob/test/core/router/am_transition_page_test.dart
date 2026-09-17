import 'package:auto_mob_v1/core/router/am_transition_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa solo opacity senza traslare la pagina', (tester) async {
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
    addTearDown(animation.dispose);
    final page = AmFadeThroughPage<void>(
      child: const SizedBox(key: Key('transition-child')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => page.transitionsBuilder(
            context,
            animation,
            kAlwaysDismissedAnimation,
            page.child,
          ),
        ),
      ),
    );

    final fadeFinder = find.byKey(const Key('am-route-opacity-transition'));
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

  testWidgets('mantiene direction solo per compatibilita', (tester) async {
    final animation = AnimationController(vsync: const TestVSync(), value: 0);
    addTearDown(animation.dispose);
    final page = AmFadeThroughPage<void>(
      direction: AmPageSlideDirection.fromLeft,
      child: const SizedBox(key: Key('transition-child')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => page.transitionsBuilder(
            context,
            animation,
            kAlwaysDismissedAnimation,
            page.child,
          ),
        ),
      ),
    );

    final fadeFinder = find.byKey(const Key('am-route-opacity-transition'));
    expect(fadeFinder, findsOneWidget);
    expect(
      find.descendant(of: fadeFinder, matching: find.byType(SlideTransition)),
      findsNothing,
    );
  });
}
