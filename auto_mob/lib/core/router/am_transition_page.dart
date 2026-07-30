import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transizione unica dell'app per le pagine PUSHATE (non le tab, che con
/// indexedStack cambiano istantanee): fade + un leggero scale, stile iOS.
///
/// E' una [CustomTransitionPage] -> resta una `PageRoute` a tutti gli effetti,
/// quindi le [Hero] animation continuano a "volare" durante la transizione.
class AmFadeThroughPage<T> extends CustomTransitionPage<T> {
  AmFadeThroughPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _FadeThroughTransition(animation: animation, child: child),
        );
}

/// Il "corpo" della transizione, come widget class (niente funzioni che
/// ritornano Widget — vedi regole architetturali).
class _FadeThroughTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeThroughTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
