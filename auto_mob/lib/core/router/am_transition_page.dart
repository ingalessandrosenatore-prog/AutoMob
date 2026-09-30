import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'am_cover_route_animation.dart';

enum AmPageSlideDirection { fromRight, fromLeft }

/// Transizione in opacità per le pagine pushate.
///
/// Nome e [direction] restano invariati per compatibilità con i chiamanti.
/// Le route non traslano superfici Liquid Glass: shader e contenuto devono
/// rimanere nello stesso sistema di coordinate durante tutta l'animazione.
class AmFadeThroughPage<T> extends CustomTransitionPage<T> {
  AmFadeThroughPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.direction = AmPageSlideDirection.fromRight,
  }) : super(
         transitionDuration: const Duration(milliseconds: 420),
         reverseTransitionDuration: const Duration(milliseconds: 360),
         transitionsBuilder: (context, animation, secondaryAnimation, child) =>
             _OpacityRouteTransition(animation: animation, child: child),
       );

  final AmPageSlideDirection direction;
}

class _OpacityRouteTransition extends StatelessWidget {
  const _OpacityRouteTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.3, 1, curve: Curves.easeInCubic),
    );
    return FadeTransition(
      key: const Key('am-route-opacity-transition'),
      opacity: progress,
      child: AmCoverRouteAnimationBinding(child: child),
    );
  }
}
