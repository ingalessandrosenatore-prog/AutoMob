import 'package:auto_mob_v1/features/dashboard/presentation/widgets/dashboard_scroll_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'pausa per scroll verticale e PageView fino alla fine dell inerzia',
    (tester) async {
      final activity = DashboardScrollActivity();
      final vertical = ScrollController(
        onAttach: activity.attach,
        onDetach: activity.detach,
      );
      final horizontal = PageController(
        onAttach: activity.attach,
        onDetach: activity.detach,
      );
      addTearDown(() {
        vertical.dispose();
        horizontal.dispose();
        activity.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: vertical,
              children: [
                SizedBox(
                  height: 200,
                  child: PageView(
                    controller: horizontal,
                    children: const [Text('a'), Text('b'), Text('c')],
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      expect(activity.value, isFalse);
      final swipe = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await swipe.moveBy(const Offset(-50, 0));
      await tester.pump();
      await swipe.moveBy(const Offset(-280, 0));
      await tester.pump();
      expect(activity.value, isTrue);
      await swipe.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(activity.value, isTrue);
      await tester.pumpAndSettle();
      expect(activity.value, isFalse);

      final scroll = await tester.startGesture(const Offset(400, 400));
      await scroll.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(activity.value, isTrue);
      await scroll.up();
      await tester.pumpAndSettle();
      expect(activity.value, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(activity.value, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
