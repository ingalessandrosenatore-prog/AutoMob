import 'package:auto_mob_v1/core/router/am_cover_route_animation.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la route root guida al contrario il controllo sottostante', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _NestedHome()));

    await tester.tap(find.text('Apri root route'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(_underlyingOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('Root destination')),
      rootNavigator: true,
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(_underlyingOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_underlyingOpacity(tester), 1);
    expect(
      find.descendant(
        of: find.byType(AmRouteBlurTransition),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });
}

double _underlyingOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(AmRouteBlurTransition),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

class _NestedHome extends StatelessWidget {
  const _NestedHome();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        AmRouteBlurTransition(
          animation: ReverseAnimation(AmCoverRouteAnimation.animation),
          child: const SizedBox(width: 48, height: 48),
        ),
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder<void>(
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, _, _) => const AmCoverRouteAnimationBinding(
                child: Scaffold(body: Text('Root destination')),
              ),
            ),
          ),
          child: const Text('Apri root route'),
        ),
      ],
    ),
  );
}
