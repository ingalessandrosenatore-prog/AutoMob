import 'package:flutter/material.dart';
import 'package:scroll_edge_blur/scroll_edge_blur.dart' as seb;
import 'package:soft_edge_blur/soft_edge_blur.dart';

/// Sfumatura ai bordi "smart" che sceglie tramite il booleano [blur] se usare
/// il vero shader GPU progressivo ([seb.EdgeBlur] di `scroll_edge_blur`)
/// oppure il gradiente soft leggero ([_EdgeGradient]).
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

  /// Pre-compila lo shader di `scroll_edge_blur` all'avvio per evitare jank al
  /// primo frame.
  static Future<void> precache() => seb.EdgeBlur.precache();

  @override
  Widget build(BuildContext context) {
    final useShader = blur && seb.EdgeBlur.isSupported;

    return ClipRect(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          for (final edge in edges)
            useShader
                ? _ScrollEdgeBlurBand(
                    edge: edge,
                    fallbackTint: fallbackTint,
                    opacity: opacity,
                  )
                : _EdgeGradient(
                    edge: edge,
                    fallbackTint: fallbackTint,
                    opacity: opacity,
                  ),
        ],
      ),
    );
  }
}

class _ScrollEdgeBlurBand extends StatelessWidget {
  const _ScrollEdgeBlurBand({
    required this.edge,
    required this.fallbackTint,
    required this.opacity,
  });

  final EdgeBlur edge;
  final Color fallbackTint;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final baseTint = edge.tintColor ?? fallbackTint;
    final shaderTint = baseTint.withValues(
      alpha: (opacity * 0.55).clamp(0.0, 1.0),
    );
    final fallbackColor = baseTint.withValues(alpha: opacity);

    final blurEdge = switch (edge.type) {
      EdgeType.topEdge => seb.BlurEdge.top,
      EdgeType.bottomEdge => seb.BlurEdge.bottom,
      EdgeType.leftEdge => seb.BlurEdge.left,
      EdgeType.rightEdge => seb.BlurEdge.right,
    };

    final band = seb.EdgeBlur(
      edge: blurEdge,
      sigma: edge.sigma,
      tint: shaderTint,
      fallbackColor: fallbackColor,
    );

    return switch (edge.type) {
      EdgeType.topEdge => Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: edge.size,
        child: band,
      ),
      EdgeType.bottomEdge => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: edge.size,
        child: band,
      ),
      EdgeType.leftEdge => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: edge.size,
        child: band,
      ),
      EdgeType.rightEdge => Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: edge.size,
        child: band,
      ),
    };
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
