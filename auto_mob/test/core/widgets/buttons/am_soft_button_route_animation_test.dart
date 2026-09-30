import 'package:common_ui_widget/common_ui_widget.dart'
    show AmRouteBlurTransition, AmSoftButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('il soft button owner inoltra la route animation condivisa', (
    tester,
  ) async {
    final animation = AnimationController(vsync: const TestVSync(), value: 0);
    addTearDown(animation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AmSoftButton(
          width: 48,
          height: 48,
          icon: HugeIcons.strokeRoundedAdd01,
          routeAnimation: animation,
        ),
      ),
    );

    expect(find.byType(AmRouteBlurTransition), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    animation.value = 1;
    await tester.pump();

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('segue davvero push e pop della ModalRoute', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              PageRouteBuilder<void>(
                transitionDuration: const Duration(milliseconds: 400),
                reverseTransitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, _, _) => const _RouteAnimatedButtonPage(),
              ),
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pump();
    await tester.pump();
    expect(_opacityOf(tester), 0);

    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacityOf(tester), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacityOf(tester), 1);

    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacityOf(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.byType(_RouteAnimatedButtonPage), findsNothing);
  });
}

double _opacityOf(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity)).opacity;

class _RouteAnimatedButtonPage extends StatelessWidget {
  const _RouteAnimatedButtonPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: AmSoftButton(
        width: 48,
        height: 48,
        icon: HugeIcons.strokeRoundedArrowLeft01,
        routeAnimation: ModalRoute.of(context)?.animation,
      ),
    ),
  );
}
