import 'package:flutter/material.dart';

import '../../theme/am_theme_colors.dart';

/// Sfumatura morbida ai bordi superiore e inferiore di un contenuto.
///
/// La fascia usa il colore di sfondo del tema: rimane visibile fino al 50%
/// e sfuma completamente entro il 100%. Il rendering e' statico e quindi non
/// ricampiona il contenuto durante lo scroll.
class AmEdgeBlur extends StatelessWidget {
  const AmEdgeBlur({
    required this.child,
    super.key,
    this.edgeExtent = 20,
    this.opacity = 0.96,
  });

  final Widget child;
  final double edgeExtent;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final background = AmThemeColors.of(context).background;

    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          children: [
            child,
            _EdgeFade(
              alignment: Alignment.topCenter,
              extent: edgeExtent,
              color: background,
              opacity: opacity,
            ),
            _EdgeFade(
              alignment: Alignment.bottomCenter,
              extent: edgeExtent,
              color: background,
              opacity: opacity,
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.alignment,
    required this.extent,
    required this.color,
    required this.opacity,
  });

  final Alignment alignment;
  final double extent;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topCenter;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      height: extent,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignment,
              end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
      ),
    );
  }
}
