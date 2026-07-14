import 'package:flutter/material.dart';

/// Hero condiviso tra il bottone "+" e il pulsante di chiusura della pagina
/// aperta. L'icona resta sempre [Icons.add]: ruotandola di 45 gradi diventa
/// una "x", cosi' il cambio di stato risulta continuo.
///
class AmFabHero extends StatelessWidget {
  final Widget child;
  final String tag;

  const AmFabHero({
    super.key,
    required this.child,
    this.tag = 'fab-aggiungi-veicolo',
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      // During the flight always paint the destination widget. This avoids
      // the source/destination subtree swap that made the icon blink.
      flightShuttleBuilder: (context, animation, direction, from, to) =>
          to.widget,
      child: child,
    );
  }
}
