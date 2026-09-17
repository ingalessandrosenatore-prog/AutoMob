import 'package:auto_mob_v1/features/dashboard/presentation/widgets/card_auto_swiper.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa lo stesso card stack swiper delle officine', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmVehicleSwiper(
            cards: const [Text('Auto 1'), Text('Auto 2')],
            initialIndex: 1,
            onVehicleChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CardStackSwiper), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    final swiper = tester.widget<CardStackSwiper>(find.byType(CardStackSwiper));
    expect(swiper.cardsCount, 2);
    expect(swiper.initialIndex, 1);
    expect(swiper.maxAngle, 0);
    expect(swiper.backCardAngle, 0);
  });

  testWidgets('disabilita lo swipe con una sola auto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmVehicleSwiper(
            cards: const [Text('Auto 1')],
            onVehicleChanged: (_) {},
          ),
        ),
      ),
    );

    final swiper = tester.widget<CardStackSwiper>(find.byType(CardStackSwiper));
    expect(swiper.isDisabled, isTrue);
  });

  testWidgets('swipe sinistro fa +1 e swipe destro fa -1', (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmVehicleSwiper(
            cards: const [Text('Auto 1'), Text('Auto 2'), Text('Auto 3')],
            initialIndex: 1,
            onVehicleChanged: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    final swiper = tester.widget<CardStackSwiper>(find.byType(CardStackSwiper));
    await swiper.onSwipe!(1, 2, CardStackSwiperDirection.left);
    expect(selectedIndex, 2);

    await swiper.onSwipe!(1, 2, CardStackSwiperDirection.right);
    expect(selectedIndex, 0);

    await swiper.onSwipe!(0, 1, CardStackSwiperDirection.right);
    expect(selectedIndex, 2);
  });
}
