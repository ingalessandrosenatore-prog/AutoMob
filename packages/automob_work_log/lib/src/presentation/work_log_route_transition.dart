import 'dart:async';

import 'package:flutter/material.dart';

typedef WorkLogRoutePageBuilder =
    Widget Function(BuildContext context, Animation<double> animation);

/// Coordina le route interne WorkLog senza animare la pagina sottostante.
class WorkLogRouteTransitionCoordinator {
  Future<T?> push<T>(
    NavigatorState navigator, {
    required WorkLogRoutePageBuilder builder,
  }) async {
    final route = WorkLogSlidePageRoute<T>(builder: builder);
    final result = navigator.push<T>(route);
    final animation = route.animation;
    if (animation == null) {
      return result;
    }

    final value = await result;
    await _waitUntilDismissed(animation);
    return value;
  }

  Future<void> _waitUntilDismissed(Animation<double> animation) {
    if (animation.status == AnimationStatus.dismissed) {
      return Future.value();
    }
    final completer = Completer<void>();

    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.dismissed || completer.isCompleted) return;
      animation.removeStatusListener(onStatus);
      completer.complete();
    }

    animation.addStatusListener(onStatus);
    return completer.future;
  }
}

class WorkLogSlidePageRoute<T> extends PageRouteBuilder<T> {
  WorkLogSlidePageRoute({required WorkLogRoutePageBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context, animation),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            _WorkLogOpacityTransition(animation: animation, child: child),
      );
}

class _WorkLogOpacityTransition extends StatelessWidget {
  const _WorkLogOpacityTransition({
    required this.animation,
    required this.child,
  });

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
      key: const Key('work-log-route-opacity-transition'),
      opacity: progress,
      child: child,
    );
  }
}
