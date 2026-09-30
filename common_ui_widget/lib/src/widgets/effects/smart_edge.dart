import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

/// Sfumatura ai bordi "smart" che adatta l'effetto alla fascia del device.
///
/// Il ramo di blur reale e' temporaneamente disattivato: vengono sempre usati
/// gradienti statici per evitare sia il canvas nero sia il sampling continuo.
class SmartEdge extends StatelessWidget {
  const SmartEdge({
    required this.blur,
    required this.edges,
    required this.child,
    super.key,
    this.fallbackTint = Colors.transparent,
    this.opacity = 0.92,
  });

  final bool blur;
  final List<EdgeBlur> edges;
  final Color fallbackTint;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Il ramo SoftEdgeBlur resta sospeso finche' il compositing della Home non
    // mantiene stabilmente il colore del tema al posto del canvas nero.

    return ClipRect(
      child: Stack(
        children: [
          child,
          for (final edge in edges)
            _EdgeGradient(
              edge: edge,
              fallbackTint: fallbackTint,
              opacity: opacity,
            ),
        ],
      ),
    );
  }
}

class _EdgeGradient extends StatelessWidget {
  const _EdgeGradient({
    required this.edge,
    required this.fallbackTint,
    required this.opacity,
  });

  final EdgeBlur edge;
  final Color fallbackTint;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tint = edge.tintColor ?? fallbackTint;
    final points = [...edge.controlPoints]
      ..sort((a, b) => a.position.compareTo(b.position));
    final stops = points.map((point) => point.position).toList();
    final colors = points
        .map(
          (point) => point.type == ControlPointType.visible
              ? tint.withValues(alpha: opacity)
              : tint.withValues(alpha: 0),
        )
        .toList();

    return switch (edge.type) {
      EdgeType.topEdge => Positioned(
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
                stops: stops,
              ),
            ),
          ),
        ),
      ),
      EdgeType.bottomEdge => Positioned(
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
                stops: stops,
              ),
            ),
          ),
        ),
      ),
      EdgeType.leftEdge => Positioned(
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
                stops: stops,
              ),
            ),
          ),
        ),
      ),
      EdgeType.rightEdge => Positioned(
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
                stops: stops,
              ),
            ),
          ),
        ),
      ),
    };
  }
}
