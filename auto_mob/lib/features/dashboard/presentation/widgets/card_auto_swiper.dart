import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';

/// Stack orizzontale delle auto, configurato con lo stesso motore usato dalle
/// card officina. L'indice viene comunicato solo a swipe completato.
class AmVehicleSwiper extends StatelessWidget {
  const AmVehicleSwiper({
    super.key,
    required this.cards,
    required this.onVehicleChanged,
    this.initialIndex = 0,
  }) : assert(cards.length > 0);

  final List<Widget> cards;
  final ValueChanged<int> onVehicleChanged;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return CardStackSwiper(
      cardsCount: cards.length,
      initialIndex: initialIndex.clamp(0, cards.length - 1),
      isLoop: cards.length > 1,
      isDisabled: cards.length <= 1,
      maxAngle: 0,
      backCardAngle: 0,
      backCardScale: 1,
      backCardOffset: const Offset(5, 0),
      threshold: 20,
      swipeAnimationDuration: const Duration(milliseconds: 400),
      returnAnimationDuration: const Duration(milliseconds: 400),
      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
        horizontal: true,
      ),
      onSwipe: (previousIndex, currentIndex, direction) {
        final delta = switch (direction) {
          CardStackSwiperDirection.left => 1,
          CardStackSwiperDirection.right => -1,
          _ => 0,
        };
        if (delta != 0) {
          onVehicleChanged((previousIndex + delta) % cards.length);
        }
        return true;
      },
      cardBuilder: (context, index, horizontal, vertical) => cards[index],
    );
  }
}
