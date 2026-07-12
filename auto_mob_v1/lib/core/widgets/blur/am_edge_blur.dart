import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../../config/performance_flags.dart';

/// Sfumatura morbida e uniforme ai bordi (alto + basso) usata in TUTTI i pop-up.
///
/// - Blur leggero ("chiaro"): sigma basso e niente tinta scura.
/// - Isolato in [RepaintBoundary]: col contenuto statico il layer del blur
///   viene messo in cache e non si ricalcola a ogni frame quando un antenato
///   si ripinge (es. mentre la tastiera sale).
///
/// Si usa avvolgendo l'area scrollabile:  `AmEdgeBlur(child: SingleChildScrollView(...))`
class AmEdgeBlur extends StatelessWidget {
  final Widget child;

  const AmEdgeBlur({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SmartEdge(
        edges: [
          EdgeBlur(
            type: EdgeType.topEdge,
            size: 20,
            sigma: 10,
            controlPoints: [
              ControlPoint(position: 0.5, type: ControlPointType.visible),
              ControlPoint(position: 1.0, type: ControlPointType.transparent),
            ],
          ),
          EdgeBlur(
            type: EdgeType.bottomEdge,
            size: 20,
            sigma: 10,
            controlPoints: [
              ControlPoint(position: 0.5, type: ControlPointType.visible),
              ControlPoint(position: 1.0, type: ControlPointType.transparent),
            ],
          ),
        ],
        blur: kHeavyEffects,
        fallbackTint: Colors.black,
        child: child,
      ),
    );
  }
}
