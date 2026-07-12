
import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

/// Sfumatura ai bordi "smart" che adatta l'effetto alla fascia del device.
///
/// - [blur] = true  → vero [SoftEdgeBlur]: campiona il contenuto e applica un
///   blur gaussiano ai bordi. Ricampiona a OGNI frame durante lo scroll →
///   pesantissimo, solo top di gamma.
/// - [blur] = false → nessun sampling: disegna solo dei **gradienti** statici
///   (dal [EdgeBlur.tintColor] verso il trasparente) sopra al contenuto. Stesso
///   "fade" visivo ai bordi ma costo GPU ~zero → medio/basso di gamma.
///
/// In entrambi i rami si passa la **stessa identica** lista di [edges], così
/// basta cambiare [blur] per passare da un rendering all'altro.
class SmartEdge extends StatelessWidget {
  /// true = blur reale, false = gradienti statici leggeri.
  final bool blur;

  /// Stessa configurazione accettata da [SoftEdgeBlur].
  final List<EdgeBlur> edges;

  /// Colore del gradiente quando un edge non ha [EdgeBlur.tintColor]
  /// (rilevante solo nel ramo [blur] == false).
  final Color fallbackTint;

  final Widget child;

  const SmartEdge({
    super.key,
    required this.blur,
    required this.edges,
    required this.child,
    this.fallbackTint = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {

    return ClipRect(
      child: Stack(
        children: [
          child,
          for (final edge in edges)
            _EdgeGradient(edge: edge, fallbackTint: fallbackTint),
        ],
      ),
    );
  }
}

/// Singola fascia di gradiente che imita il fade di un [EdgeBlur] senza blur.
/// Va dentro lo [Stack] di [SmartEdge] (ritorna un [Positioned]).
class _EdgeGradient extends StatelessWidget {
  final EdgeBlur edge;
  final Color fallbackTint;

  const _EdgeGradient({required this.edge, required this.fallbackTint});

  @override
  Widget build(BuildContext context) {
    final tint = edge.tintColor ?? fallbackTint;
    // Pieno al bordo esterno -> trasparente verso l'interno.
    final colors = [tint, tint.withValues(alpha: 0.0)];

    switch (edge.type) {
      case EdgeType.topEdge:
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: edge.size,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
          ),
        );
      case EdgeType.bottomEdge:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: edge.size,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: colors,
                ),
              ),
            ),
          ),
        );
      case EdgeType.leftEdge:
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: edge.size,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                ),
              ),
            ),
          ),
        );
      case EdgeType.rightEdge:
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: edge.size,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: colors,
                ),
              ),
            ),
          ),
        );
    }
  }
}
