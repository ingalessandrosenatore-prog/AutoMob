import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Applica una transizione blur e fade guidata da una route.
///
/// Se [animation] non viene fornita, [child] viene restituito direttamente e
/// il widget non aggiunge alcun effetto o listener.
class AmRouteBlurTransition extends StatelessWidget {
  const AmRouteBlurTransition({required this.child, super.key, this.animation});

  static const _maxBlurSigma = 10.0;
  static const _blurThreshold = 0.01;

  final Animation<double>? animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final routeAnimation = animation;
    if (routeAnimation == null) return child;

    return AnimatedBuilder(
      animation: routeAnimation,
      child: child,
      builder: (context, child) {
        final routeValue = routeAnimation.value.clamp(0.0, 1.0);
        final opacityProgress = Curves.easeOutCubic.transform(routeValue);
        // La curva separata mantiene il blur leggibile mentre il child appare.
        final effectProgress = Curves.easeInOutCubic.transform(routeValue);
        final blurSigma = _maxBlurSigma * (1 - effectProgress);

        return Opacity(
          opacity: opacityProgress,
          child: ImageFiltered(
            enabled: blurSigma > _blurThreshold,
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: child,
          ),
        );
      },
    );
  }
}
