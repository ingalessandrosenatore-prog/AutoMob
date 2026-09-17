import 'package:auto_mob_v1/core/router/am_animated_branch_container.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('naviga con un vero PageView e uno ScrollPosition condiviso', (
    tester,
  ) async {
    var homeHasScrollPosition = false;
    var historyHasScrollPosition = false;
    Listenable? homeRepaint;
    Listenable? historyRepaint;
    final pageMotionStates = <bool>[];

    Widget page(
      String label,
      ValueSetter<bool> onBuilt,
      ValueSetter<Listenable?> onRepaint,
    ) => Builder(
      builder: (context) {
        onBuilt(Scrollable.maybeOf(context) != null);
        onRepaint(AmShellBranchRepaintScope.maybeOf(context));
        pageMotionStates.add(AmLiquidGlassMotionScope.isMovingOf(context));
        return Center(child: Text(label));
      },
    );

    Widget host(int index) => MaterialApp(
      home: AmAnimatedBranchContainer(
        currentIndex: index,
        children: [
          page(
            'Home',
            (value) => homeHasScrollPosition = value,
            (value) => homeRepaint = value,
          ),
          page(
            'History',
            (value) => historyHasScrollPosition = value,
            (value) => historyRepaint = value,
          ),
        ],
      ),
    );

    await tester.pumpWidget(host(0));

    expect(find.byType(PageView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AmAnimatedBranchContainer),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AmAnimatedBranchContainer),
        matching: find.byType(TickerMode),
      ),
      findsNothing,
    );
    expect(homeHasScrollPosition, isTrue);
    expect(homeRepaint, isNotNull);
    expect(pageMotionStates.last, isFalse);

    var repaintNotifications = 0;
    homeRepaint!.addListener(() => repaintNotifications++);

    final viewportWidth = tester.getSize(find.byType(PageView)).width;
    await tester.pumpWidget(host(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(historyHasScrollPosition, isTrue);
    expect(pageMotionStates.last, isTrue);
    expect(historyRepaint, isNot(same(homeRepaint)));
    expect(repaintNotifications, greaterThan(0));
    final homeLeft = tester.getTopLeft(find.text('Home')).dx;
    final historyLeft = tester.getTopLeft(find.text('History')).dx;
    expect(homeLeft, lessThan(0));
    expect(historyLeft, inExclusiveRange(0, viewportWidth));

    await tester.pumpAndSettle();
    expect(pageMotionStates.last, isFalse);
    expect(
      tester.getCenter(find.text('History')).dx,
      closeTo(viewportWidth / 2, 0.01),
    );

    final homeRepaintBeforeReturn = homeRepaint;
    await tester.pumpWidget(host(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(homeRepaint, isNot(same(homeRepaintBeforeReturn)));
    var returnNotifications = 0;
    homeRepaint!.addListener(() => returnNotifications++);
    expect(tester.getTopLeft(find.text('History')).dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(returnNotifications, greaterThan(0));
    expect(
      tester.getCenter(find.text('Home')).dx,
      closeTo(viewportWidth / 2, 0.01),
    );

    for (var iteration = 0; iteration < 2; iteration++) {
      final previousHistoryRepaint = historyRepaint;
      await tester.pumpWidget(host(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(historyRepaint, isNot(same(previousHistoryRepaint)));
      var historyNotifications = 0;
      historyRepaint!.addListener(() => historyNotifications++);
      await tester.pumpAndSettle();
      expect(historyNotifications, greaterThan(0));

      final previousHomeRepaint = homeRepaint;
      await tester.pumpWidget(host(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(homeRepaint, isNot(same(previousHomeRepaint)));
      var homeNotifications = 0;
      homeRepaint!.addListener(() => homeNotifications++);
      await tester.pumpAndSettle();
      expect(homeNotifications, greaterThan(0));
    }
  });
}
