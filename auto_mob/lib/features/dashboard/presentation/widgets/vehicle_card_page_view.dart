import 'package:flutter/material.dart';

/// Scorrimento orizzontale nativo delle card veicolo.
class VehicleCardPageView extends StatelessWidget {
  const VehicleCardPageView({
    required this.controller,
    required this.cards,
    required this.onPageChanged,
    super.key,
  }) : assert(cards.length > 0);

  final PageController controller;
  final List<Widget> cards;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      itemCount: cards.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) => cards[index],
    );
  }
}
