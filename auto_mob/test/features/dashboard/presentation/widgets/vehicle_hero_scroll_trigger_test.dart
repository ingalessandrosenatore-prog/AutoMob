import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_scroll_trigger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('waits for scroll even when the scene is initially visible', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var starts = 0;
    await tester.pumpWidget(
      _Dashboard(
        controller: controller,
        beforeScene: 100,
        onReveal: () => starts++,
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(starts, 0);

    final scroll = await tester.startGesture(const Offset(400, 350));
    await scroll.moveBy(const Offset(0, -125));
    await tester.pump(const Duration(seconds: 1));
    expect(starts, 0);
    await scroll.up();
    await tester.pumpAndSettle();
    expect(starts, 1);

    controller.jumpTo(700);
    await tester.pumpAndSettle();
    controller.jumpTo(0);
    await tester.pumpAndSettle();
    expect(starts, 1);
  });

  testWidgets('waits for the scene to load after scrolling into view', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var starts = 0;
    void reveal() => starts++;
    await tester.pumpWidget(
      _Dashboard(
        controller: controller,
        beforeScene: 750,
        ready: false,
        onReveal: reveal,
      ),
    );

    controller.jumpTo(430);
    await tester.pumpAndSettle();
    expect(starts, 0);
    await tester.pumpWidget(
      _Dashboard(controller: controller, beforeScene: 750, onReveal: reveal),
    );
    await tester.pumpAndSettle();
    expect(starts, 1);
  });

  testWidgets('does not count the portion hidden behind the pinned header', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var starts = 0;
    await tester.pumpWidget(
      _Dashboard(
        controller: controller,
        beforeScene: 750,
        onReveal: () => starts++,
      ),
    );

    controller.jumpTo(270);
    await tester.pumpAndSettle();
    expect(starts, 0);
    controller.jumpTo(995);
    await tester.pumpAndSettle();
    expect(starts, 0);
    controller.jumpTo(890);
    await tester.pumpAndSettle();
    expect(starts, 1);
  });
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.controller,
    required this.beforeScene,
    required this.onReveal,
    this.ready = true,
  });

  final ScrollController controller;
  final double beforeScene;
  final VoidCallback onReveal;
  final bool ready;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        controller: controller,
        slivers: [
          const SliverAppBar(pinned: true, toolbarHeight: 72, primary: false),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: beforeScene),
                VehicleHeroScrollTrigger(
                  ready: ready,
                  topObstruction: 72,
                  onReveal: onReveal,
                  child: const SizedBox(height: 300, width: double.infinity),
                ),
                const SizedBox(height: 650),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
