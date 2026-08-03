import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import 'mechanic_shapes.dart';

class MechanicGlassIconButton extends StatelessWidget {
  const MechanicGlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.dimension = 54,
    this.foregroundColor,
  }) : assert(dimension >= mechanicMinimumTouchTarget);

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double dimension;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return SizedBox.square(
      dimension: dimension,
      child: OCLiquidGlass(
        width: dimension,
        height: dimension,
        borderRadius: dimension / 2,
        color: colors.surfaceRaised.withValues(alpha: 0.24),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(
            icon,
            color:
                foregroundColor ??
                (onPressed == null ? colors.textSecondary : colors.textPrimary),
            size: 24,
          ),
        ),
      ),
    );
  }
}
