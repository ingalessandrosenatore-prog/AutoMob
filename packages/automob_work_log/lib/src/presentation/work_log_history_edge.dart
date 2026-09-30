import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:common_ui_widget/performance_flags.dart';
import 'package:flutter/material.dart';

/// Applica alla history gli stessi bordi sfumati usati dalla Home owner.
class WorkLogHistoryEdge extends StatelessWidget {
  const WorkLogHistoryEdge({
    required this.backgroundColor,
    required this.accentColor,
    required this.child,
    super.key,
  });

  final Color backgroundColor;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => SmartEdge(
    blur: kHeavyEffects,
    opacity: 0.96,
    fallbackTint: backgroundColor,
    edges: [
      EdgeBlur(
        type: EdgeType.topEdge,
        size: 120,
        tintColor: backgroundColor,
        sigma: 10,
        controlPoints: [
          ControlPoint(position: 0.5, type: ControlPointType.visible),
          ControlPoint(position: 1, type: ControlPointType.transparent),
        ],
      ),
      EdgeBlur(
        type: EdgeType.bottomEdge,
        size: 32,
        tintColor: backgroundColor,
        sigma: 10,
        controlPoints: [
          ControlPoint(position: 0.5, type: ControlPointType.visible),
          ControlPoint(position: 1, type: ControlPointType.transparent),
        ],
      ),
    ],
    child: child,
  );
}
