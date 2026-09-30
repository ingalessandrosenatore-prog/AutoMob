import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_card_page_view.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa un PageView orizzontale al posto dello stack swiper', (
    tester,
  ) async {
    final controller = PageController(initialPage: 1);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: VehicleCardPageView(
              controller: controller,
              cards: const [Text('Auto 0'), Text('Auto 1'), Text('Auto 2')],
              onPageChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.scrollDirection, Axis.horizontal);
    expect(find.byType(CardStackSwiper), findsNothing);
  });

  testWidgets(
    'lo swipe destro mostra la precedente e il sinistro la seguente',
    (tester) async {
      final controller = PageController(initialPage: 1);
      addTearDown(controller.dispose);
      final selectedIndexes = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: VehicleCardPageView(
                controller: controller,
                cards: const [Text('Auto 0'), Text('Auto 1'), Text('Auto 2')],
                onPageChanged: selectedIndexes.add,
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(PageView), const Offset(320, 0));
      await tester.pumpAndSettle();
      expect(selectedIndexes.last, 0);

      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(selectedIndexes.last, 1);
    },
  );
}
