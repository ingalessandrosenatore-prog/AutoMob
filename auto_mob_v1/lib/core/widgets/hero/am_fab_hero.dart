import 'package:flutter/material.dart';

/// Hero condiviso tra il bottone "+" della home e il bottone "chiudi" della
/// pagina di registrazione veicolo: l'icona vola dall'uno all'altro durante la
/// transizione di pagina.
///
/// Durante il volo NON mostriamo il bottone reale ma un PROXY statico (cerchio
/// pieno con icona): i bottoni sono `OCLiquidGlass` (shader), e uno shader in
/// volo sfarfalla / si reinizializza. Il proxy e' un semplice Container.
class AmFabHero extends StatelessWidget {
  final Widget child;
  final String tag;
  final double size;
  final Color proxyColor;
  final IconData proxyIcon;

  const AmFabHero({
    super.key,
    required this.child,
    this.tag = 'fab-aggiungi-veicolo',
    this.size = 45,
    this.proxyColor = const Color(0xFFFF6B00),
    this.proxyIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (_, _, _, _, _) => Material(
        color: Colors.transparent,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: proxyColor,
            shape: BoxShape.circle,
          ),
          child: Icon(proxyIcon, color: Colors.white, size: 26),
        ),
      ),
      child: child,
    );
  }
}
