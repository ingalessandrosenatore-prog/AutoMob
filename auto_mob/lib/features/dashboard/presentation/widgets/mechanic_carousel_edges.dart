import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// @brief Sfumatura laterale condivisa, senza filtri sul render 3D animato.
class MechanicCarouselEdges extends StatelessWidget {
  const MechanicCarouselEdges({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SmartEdge(
    blur: false,
    fallbackTint: AmThemeColors.of(context).background,
    edges: [
      for (final side in [EdgeType.leftEdge, EdgeType.rightEdge])
        EdgeBlur(
          type: side,
          size: 100,
          sigma: 0,
          controlPoints: [
            ControlPoint(position: 0, type: ControlPointType.visible),
            ControlPoint(position: 1, type: ControlPointType.transparent),
          ],
        ),
    ],
    child: child,
  );
}
