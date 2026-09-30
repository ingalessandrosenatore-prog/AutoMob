import 'package:flutter/widgets.dart';

/// Collega l'animazione di una route root alle pagine persistenti sottostanti.
abstract final class AmCoverRouteAnimation {
  static final ProxyAnimation _animation = ProxyAnimation(
    kAlwaysDismissedAnimation,
  );

  static Animation<double> get animation => _animation;

  static void attach(Animation<double> animation) {
    _animation.parent = animation;
  }

  static void detach(Animation<double> animation) {
    if (identical(_animation.parent, animation)) {
      _animation.parent = kAlwaysDismissedAnimation;
    }
  }
}

/// Pubblica la primary animation della [ModalRoute] finché [child] è montato.
class AmCoverRouteAnimationBinding extends StatefulWidget {
  const AmCoverRouteAnimationBinding({required this.child, super.key});

  final Widget child;

  @override
  State<AmCoverRouteAnimationBinding> createState() =>
      _AmCoverRouteAnimationBindingState();
}

class _AmCoverRouteAnimationBindingState
    extends State<AmCoverRouteAnimationBinding> {
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextAnimation = ModalRoute.of(context)?.animation;
    if (identical(nextAnimation, _routeAnimation)) return;
    final previousAnimation = _routeAnimation;
    _routeAnimation = nextAnimation;
    // Cambiare il parent del ProxyAnimation notifica la Home: lo facciamo a
    // fine frame per non marcarla dirty mentre la nuova route sta costruendo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (previousAnimation != null) {
        AmCoverRouteAnimation.detach(previousAnimation);
      }
      if (mounted &&
          nextAnimation != null &&
          identical(_routeAnimation, nextAnimation)) {
        AmCoverRouteAnimation.attach(nextAnimation);
      }
    });
  }

  @override
  void dispose() {
    final routeAnimation = _routeAnimation;
    if (routeAnimation != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => AmCoverRouteAnimation.detach(routeAnimation),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
