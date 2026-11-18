import 'package:flutter/material.dart';
import 'package:scroll_edge_blur/scroll_edge_blur.dart' as seb;

import '../../performance_flags.dart';
import '../../theme/am_theme_colors.dart';

/// Sfumatura morbida ai bordi superiore e inferiore di un contenuto.
///
/// Se [blur] è `true`, applica lo shader GPU progressivo di `scroll_edge_blur`
/// alle fasce superiore e inferiore; altrimenti usa il gradiente statico.
class AmEdgeBlur extends StatelessWidget {
  const AmEdgeBlur({
    required this.child,
    super.key,
    this.edgeExtent = 10,
    this.opacity = 0.96,
    this.blur = kHeavyEffects,
    this.sigma = 12,
  });

  final Widget child;
  final double edgeExtent;
  final double opacity;
  final bool blur;
  final double sigma;

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
              blur: blur,
              sigma: sigma,
            ),
            _EdgeFade(
              alignment: Alignment.bottomCenter,
              extent: edgeExtent,
              color: background,
              opacity: opacity,
              blur: blur,
              sigma: sigma,
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
    required this.blur,
    required this.sigma,
  });

  final Alignment alignment;
  final double extent;
  final Color color;
  final double opacity;
  final bool blur;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topCenter;

    final useShader = blur && seb.EdgeBlur.isSupported;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      height: extent,
      child: useShader
          ? seb.EdgeBlur(
              edge: isTop ? seb.BlurEdge.top : seb.BlurEdge.bottom,
              sigma: sigma,
              tint: color.withValues(alpha: (opacity * 0.55).clamp(0.0, 1.0)),
              fallbackColor: color.withValues(alpha: opacity),
            )
          : IgnorePointer(
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
